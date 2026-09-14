# ==============================================================================
# Script Name: Deploy-AppUninstaller.ps1
# Description: Professional System App Uninstaller (Bulk Uninstall + Final UI Fix)
# Developer: argtek
# Execution Context: SYSTEM / Administrator
# ==============================================================================

[CmdletBinding()]
param()

# --- CONFIGURATION & PATHS ---
$InstallDir     = "$env:ProgramData\AppUninstaller"
$LogDir         = "$InstallDir\Logs"
$DeploymentLog  = "$LogDir\Deployment.log"
$EngineScript   = "$InstallDir\Remove-AppEngine.ps1"
$SelectorScript = "$InstallDir\Launch-AppSelector.ps1"
$SelectionFile  = "$InstallDir\selected_app.json"
$TargetServiceUI= "$InstallDir\ServiceUI.exe"
$TaskName       = "IntuneSystemAppUninstaller"
$ShortcutPath   = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\System App Uninstaller.lnk"

# --- LOGGING FUNCTION ---
function Write-AppLog {
    param([string]$Message, [ValidateSet("INFO", "WARN", "ERROR")] [string]$Level = "INFO", [string]$Path = $DeploymentLog)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$TimeStamp] [$Level] $Message"
    if (-not (Test-Path (Split-Path $Path))) { New-Item -ItemType Directory -Path (Split-Path $Path) -Force | Out-Null }
    Add-Content -Path $Path -Value $LogEntry -ErrorAction SilentlyContinue
    Write-Output $LogEntry
}

try {
    Write-AppLog -Message "Starting deployment of Professional App Uninstaller..." -Level INFO

    # 1. CREATE DIRECTORY STRUCTURE
    if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
    if (-not (Test-Path $LogDir))     { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

    # 2. COPY SERVICEUI.EXE & LOGO
    $SourceServiceUI = "$PSScriptRoot\ServiceUI.exe"
    $SourceLogo      = "$PSScriptRoot\logo.png"

    if (Test-Path $SourceServiceUI) {
        Copy-Item -Path $SourceServiceUI -Destination $TargetServiceUI -Force
    } else {
        Write-AppLog -Message "ServiceUI.exe missing!" -Level ERROR
        exit 1
    }

    if (Test-Path $SourceLogo) { Copy-Item -Path $SourceLogo -Destination "$InstallDir\logo.png" -Force }

    # 2.5 COMPILE NATIVE HIDDEN LAUNCHER
    $HiddenApp = "$InstallDir\HiddenApp.exe"
    $CSharpCode = @"
    using System.Diagnostics;
    public class HiddenLauncher {
        public static void Main(string[] args) {
            if (args.Length > 0) {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "cmd.exe";
                psi.Arguments = "/c \"" + args[0] + "\"";
                psi.WindowStyle = ProcessWindowStyle.Hidden;
                psi.CreateNoWindow = true;
                psi.UseShellExecute = false;
                Process p = Process.Start(psi);
                p.WaitForExit();
            }
        }
    }
"@
    Add-Type -TypeDefinition $CSharpCode -Language CSharp -OutputAssembly $HiddenApp -OutputType WindowsApplication -ErrorAction SilentlyContinue

    # 3. GENERATE BACKGROUND ENGINE SCRIPT
    $EngineContent = @'
# ==============================================================================
# Execution Context: SYSTEM (Session 0) -> Bridges UI via ServiceUI (Bulk Processor)
# ==============================================================================
$InstallDir    = "$env:ProgramData\AppUninstaller"
$SelectionFile = "$InstallDir\selected_app.json"
$EngineLog     = "$InstallDir\Logs\Engine.log"

function Write-EngineLog {
    param([string]$Message, [string]$Level = "INFO")
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $EngineLog -Value "[$TimeStamp] [$Level] $Message" -ErrorAction SilentlyContinue
}

try {
    Write-EngineLog -Message "Engine triggered."
    if (-not (Test-Path $SelectionFile)) { exit 0 }

    # Parse payload as an array to handle bulk selections
    $PayloadData = Get-Content -Path $SelectionFile -Raw | ConvertFrom-Json
    $AppList = @($PayloadData)

    $ServiceUI = "$InstallDir\ServiceUI.exe"
    $HiddenApp = "$InstallDir\HiddenApp.exe"
    $WrapperScript = "$InstallDir\run_uninstall.cmd"

    foreach ($AppReq in $AppList) {
        $AppName = $AppReq.AppName
        $UninstallCmd = $AppReq.UninstallCommand
        $TargetSession = $AppReq.SessionId

        Write-EngineLog -Message "Processing uninstall for: '$AppName'"

        if ($UninstallCmd -match "msiexec") {
            $GuidMatch = [regex]::Match($UninstallCmd, '{[A-F0-9-]+}', 'IgnoreCase')
            if ($GuidMatch.Success) { $FinalCmd = "msiexec.exe /x $($GuidMatch.Value)" } 
            else { $FinalCmd = $UninstallCmd }
        } else {
            $FinalCmd = $UninstallCmd
        }

        Set-Content -Path $WrapperScript -Value "@echo off`r`n$FinalCmd" -Encoding ASCII -Force

        $SessionArg = "-session:$TargetSession"
        $PInfo = New-Object System.Diagnostics.ProcessStartInfo
        $PInfo.FileName = $ServiceUI
        
        if (Test-Path $HiddenApp) {
            $PInfo.Arguments = "$SessionArg `"$HiddenApp`" `"$WrapperScript`""
        } else {
            $PInfo.Arguments = "$SessionArg `"$env:SystemRoot\System32\cmd.exe`" /c `"$WrapperScript`""
        }
        
        $PInfo.UseShellExecute = $false
        $PInfo.CreateNoWindow = $true
        $PInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        
        $Process = [System.Diagnostics.Process]::Start($PInfo)
        $Process.WaitForExit()
        
        Remove-Item -Path $WrapperScript -Force -ErrorAction SilentlyContinue
        Write-EngineLog -Message "Finished: '$AppName'"
    }

    # Clean up JSON payload only after all apps are processed
    Remove-Item -Path $SelectionFile -Force -ErrorAction SilentlyContinue
    Write-EngineLog -Message "Bulk routine completed." -Level "INFO"

} catch {
    Write-EngineLog -Message "Engine Error: $($_.Exception.Message)" -Level "ERROR"
}
'@
    Set-Content -Path $EngineScript -Value $EngineContent -Encoding UTF8 -Force

    # 4. GENERATE USER GUI SELECTOR SCRIPT
    $SelectorContent = @'
# ==============================================================================
# Execution Context: Standard User Interactive Session
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$InstallDir    = "$env:ProgramData\AppUninstaller"
$SelectionFile = "$InstallDir\selected_app.json"
$LogoPath      = "$InstallDir\logo.png"
$UserLog       = "$InstallDir\Logs\UserGUI.log"

# Enterprise Blacklist
$BlacklistPattern = "(?i)Microsoft Edge|Google Chrome|OneDrive|Microsoft 365|Microsoft Office|Microsoft Teams|Cisco AnyConnect|GlobalProtect|Palo Alto|CrowdStrike|SentinelOne|McAfee|Symantec|Bitdefender|Windows Defender|Intune Management Extension|Configuration Manager Client"

$UninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "System Application Uninstaller"
$Form.Size = New-Object System.Drawing.Size(700, 540)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

if (Test-Path $LogoPath) {
    $PictureBox = New-Object System.Windows.Forms.PictureBox
    $PictureBox.Location = New-Object System.Drawing.Point(540, 15)
    $PictureBox.Size = New-Object System.Drawing.Size(125, 40)
    $PictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $PictureBox.Image = [System.Drawing.Image]::FromFile($LogoPath)
    $Form.Controls.Add($PictureBox)
}

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "Select applications to safely remove from this computer:"
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$TitleLabel.ForeColor = [System.Drawing.Color]::White
$TitleLabel.Location = New-Object System.Drawing.Point(15, 25)
$TitleLabel.AutoSize = $true
$Form.Controls.Add($TitleLabel)

$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Size = New-Object System.Drawing.Size(650, 350)
$Grid.Location = New-Object System.Drawing.Point(15, 65)
$Grid.SelectionMode = "FullRowSelect"
$Grid.AllowUserToAddRows = $false
$Grid.AllowUserToResizeRows = $false
$Grid.RowHeadersVisible = $false
$Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Grid.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$Grid.ReadOnly = $false # Editable so checkboxes can be checked

$Grid.EnableHeadersVisualStyles = $false
$Grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$Grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
$Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

$Grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Grid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
$Grid.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$Grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$Grid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)

$Table = New-Object System.Data.DataTable
$null = $Table.Columns.Add("Select", [System.Boolean])
$null = $Table.Columns.Add("Application Name")
$null = $Table.Columns.Add("Version")
$null = $Table.Columns.Add("Publisher")
$null = $Table.Columns.Add("UninstallCmd")

$Apps = Get-ChildItem -Path $UninstallPaths -ErrorAction SilentlyContinue | ForEach-Object {
    Get-ItemProperty -Path $_.PsPath
} | Where-Object { 
    $_.DisplayName -and $_.UninstallString -and $_.SystemComponent -ne 1 -and $_.ParentKeyName -eq $null -and ($_.DisplayName -notmatch $BlacklistPattern)
} | Select-Object DisplayName, DisplayVersion, Publisher, UninstallString | Sort-Object DisplayName

foreach ($App in $Apps) {
    $null = $Table.Rows.Add($false, $App.DisplayName, $App.DisplayVersion, $App.Publisher, $App.UninstallString)
}

$Grid.DataSource = $Table

# 1. Force the entire grid to stretch to the right edge
$Grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill

# 2. Override ONLY the Checkbox column to stay fixed at 50px
$Grid.Columns["Select"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::None
$Grid.Columns["Select"].Width = 50
$Grid.Columns["Select"].Resizable = [System.Windows.Forms.DataGridViewTriState]::False
$Grid.Columns["Select"].ReadOnly = $false

# 3. Apply FillWeights to distribute the remaining space
$Grid.Columns["Application Name"].FillWeight = 50
$Grid.Columns["Application Name"].ReadOnly = $true

$Grid.Columns["Version"].FillWeight = 20
$Grid.Columns["Version"].ReadOnly = $true

$Grid.Columns["Publisher"].FillWeight = 30
$Grid.Columns["Publisher"].ReadOnly = $true

# 4. Explicitly hide the ugly command column
$Grid.Columns["UninstallCmd"].Visible = $false

$Form.Controls.Add($Grid)

$Button = New-Object System.Windows.Forms.Button
$Button.Text = "Uninstall Selected Software"
$Button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Button.Size = New-Object System.Drawing.Size(200, 40)
$Button.Location = New-Object System.Drawing.Point(240, 435)
$Button.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$Button.ForeColor = [System.Drawing.Color]::White
$Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Button.FlatAppearance.BorderSize = 0

$DevLabel = New-Object System.Windows.Forms.Label
$DevLabel.Text = "Developed by argtek"
$DevLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$DevLabel.ForeColor = [System.Drawing.Color]::Gray
$DevLabel.Location = New-Object System.Drawing.Point(540, 455)
$DevLabel.AutoSize = $true
$Form.Controls.Add($DevLabel)

$Button.Add_Click({
    $Grid.EndEdit() # Commit any pending checkbox clicks

    $SelectedApps = @()
    $CurrentSessionId = (Get-Process -Id $PID).SessionId

    foreach ($Row in $Grid.Rows) {
        if ($Row.Cells["Select"].Value -eq $true) {
            $SelectedApps += @{
                AppName = $Row.Cells["Application Name"].Value
                UninstallCommand = $Row.Cells["UninstallCmd"].Value
                SessionId = $CurrentSessionId
            }
        }
    }

    if ($SelectedApps.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please check the box next to at least one application.", "Selection Required", 'OK', 'Warning')
        return
    }

    $AppNamesList = ($SelectedApps | ForEach-Object { $_.AppName })
    if ($AppNamesList.Count -gt 8) {
        $DisplayList = ($AppNamesList[0..7] -join "`n") + "`n...and $($AppNamesList.Count - 8) more"
    } else {
        $DisplayList = $AppNamesList -join "`n"
    }

    $Choice = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to uninstall these $($SelectedApps.Count) applications?`n`n$DisplayList",
        "Confirm Bulk Uninstallation",
        'YesNo',
        'Question'
    )

    if ($Choice -eq 'Yes') {
        $Payload = $SelectedApps | ConvertTo-Json -Depth 3
        [System.IO.File]::WriteAllText($SelectionFile, $Payload, [System.Text.Encoding]::UTF8)

        $Timeout = 0
        while (-not (Test-Path $SelectionFile) -and $Timeout -lt 10) { Start-Sleep -Milliseconds 200; $Timeout++ }

        $Result = Start-Process "schtasks.exe" -ArgumentList "/Run /TN `"IntuneSystemAppUninstaller`"" -Wait -NoNewWindow -PassThru

        if ($Result.ExitCode -eq 0) {
            
            $Button.Enabled = $false
            $Button.Text = "Uninstalling $($SelectedApps.Count) App(s)..."
            $Grid.Enabled = $false
            $Form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

            # Wait for Engine to finish ALL uninstallations and delete the payload file
            while (Test-Path $SelectionFile) {
                Start-Sleep -Milliseconds 500
                [System.Windows.Forms.Application]::DoEvents()
            }

            $Table.Rows.Clear()
            $RefreshApps = Get-ChildItem -Path $UninstallPaths -ErrorAction SilentlyContinue | ForEach-Object {
                Get-ItemProperty -Path $_.PsPath
            } | Where-Object { 
                $_.DisplayName -and $_.UninstallString -and $_.SystemComponent -ne 1 -and $_.ParentKeyName -eq $null -and ($_.DisplayName -notmatch $BlacklistPattern)
            } | Select-Object DisplayName, DisplayVersion, Publisher, UninstallString | Sort-Object DisplayName

            foreach ($AppItem in $RefreshApps) {
                $null = $Table.Rows.Add($false, $AppItem.DisplayName, $AppItem.DisplayVersion, $AppItem.Publisher, $AppItem.UninstallString)
            }

            $Button.Enabled = $true
            $Button.Text = "Uninstall Selected Software"
            $Grid.Enabled = $true
            $Form.Cursor = [System.Windows.Forms.Cursors]::Default

        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to trigger task. Code: $($Result.ExitCode)", "Task Error", 'OK', 'Error')
        }
    }
})

$Form.Controls.Add($Button)
$Form.ShowDialog() | Out-Null
'@
    Set-Content -Path $SelectorScript -Value $SelectorContent -Encoding UTF8 -Force

    # 5. APPLY NTFS SECURITY ACLs
    $Acl = Get-Acl $InstallDir
    $Acl.SetAccessRuleProtection($true, $false)
    $SystemRights = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $AdminRights  = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $UserRights   = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.AddAccessRule($SystemRights)
    $Acl.AddAccessRule($AdminRights)
    $Acl.AddAccessRule($UserRights)
    Set-Acl -Path $InstallDir -AclObject $Acl

    # 6. REGISTER SCHEDULED TASK
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$EngineScript`""
    $Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances Parallel
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Principal $Principal -Settings $Settings -Force | Out-Null
    
    $TaskFile = "$env:SystemRoot\System32\Tasks\$TaskName"
    if (Test-Path $TaskFile) {
        $TaskAcl = Get-Acl $TaskFile
        $TaskUserRights = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users", "ReadAndExecute", "Allow")
        $TaskAcl.AddAccessRule($TaskUserRights)
        Set-Acl -Path $TaskFile -AclObject $TaskAcl
    }

    # 7. CREATE START MENU SHORTCUT
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -sta -File `"$SelectorScript`""
    $Shortcut.IconLocation = "imageres.dll,89"
    $Shortcut.Description = "Interactively bulk uninstall software."
    $Shortcut.WindowStyle = 7 # 7 forces the shortcut to Run: Minimised
    $Shortcut.Save()

    Write-AppLog -Message "Deployment completed successfully." -Level INFO
    exit 0
} catch {
    Write-AppLog -Message "Fatal deployment failure: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}
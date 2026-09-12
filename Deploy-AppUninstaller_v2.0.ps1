# ==============================================================================
# Script Name: Deploy-AppUninstaller.ps1
# Description: Production-ready Interactive System App Uninstaller (Explicit Session + .NET Wrapper + Auto-Refresh)
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
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")] [string]$Level = "INFO",
        [string]$Path = $DeploymentLog
    )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$TimeStamp] [$Level] $Message"
    if (-not (Test-Path (Split-Path $Path))) { New-Item -ItemType Directory -Path (Split-Path $Path) -Force | Out-Null }
    Add-Content -Path $Path -Value $LogEntry -ErrorAction SilentlyContinue
    Write-Output $LogEntry
}

try {
    Write-AppLog -Message "Starting deployment of Interactive App Uninstaller..." -Level INFO

    # 1. CREATE DIRECTORY STRUCTURE
    if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
    if (-not (Test-Path $LogDir))     { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

    # 2. COPY SERVICEUI.EXE BINARY
    Write-AppLog -Message "Checking for ServiceUI.exe binary..." -Level INFO
    $SourceServiceUI = "$PSScriptRoot\ServiceUI.exe"

    if (Test-Path $SourceServiceUI) {
        Copy-Item -Path $SourceServiceUI -Destination $TargetServiceUI -Force
        Write-AppLog -Message "ServiceUI.exe successfully copied from package root to $InstallDir" -Level INFO
    } elseif (Test-Path "$env:SystemRoot\System32\ServiceUI.exe") {
        Copy-Item -Path "$env:SystemRoot\System32\ServiceUI.exe" -Destination $TargetServiceUI -Force
        Write-AppLog -Message "ServiceUI.exe copied from System32 to $InstallDir" -Level INFO
    } else {
        Write-AppLog -Message "ServiceUI.exe not found in installer root or System32. Ensure it is placed in $InstallDir manually." -Level WARN
    }

    # 3. GENERATE BACKGROUND ENGINE SCRIPT
    $EngineContent = @'
# ==============================================================================
# Execution Context: SYSTEM (Session 0) -> Bridges UI into Active User Session
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
    Write-EngineLog -Message "Engine triggered by user selection task."
    
    if (-not (Test-Path $SelectionFile)) {
        Write-EngineLog -Message "Selection payload file not found: $SelectionFile" -Level "WARN"
        exit 0
    }

    $Payload = Get-Content -Path $SelectionFile -Raw | ConvertFrom-Json
    $AppName = $Payload.AppName
    $UninstallCmd = $Payload.UninstallCommand
    $TargetSession = $Payload.SessionId

    Write-EngineLog -Message "Processing interactive uninstall request for: '$AppName'"
    Write-EngineLog -Message "Target Session ID from GUI: $TargetSession"

    $ServiceUI = "$InstallDir\ServiceUI.exe"
    if (-not (Test-Path $ServiceUI)) {
        Write-EngineLog -Message "ServiceUI.exe missing! System cannot project UI into user session." -Level "ERROR"
        exit 1
    }

    $SessionArg = "-session:$TargetSession"
    $CmdExe = "$env:SystemRoot\System32\cmd.exe"

    $WrapperScript = "$InstallDir\run_uninstall.cmd"

    # 1. Format the final command based on app type
	if ($UninstallCmd -match "msiexec") {
		$GuidMatch = [regex]::Match($UninstallCmd, '{[A-F0-9-]+}', 'IgnoreCase')
		if ($GuidMatch.Success) {
			$FinalCmd = "msiexec.exe /x $($GuidMatch.Value)"
		} else {
			$FinalCmd = $UninstallCmd
			Write-EngineLog -Message "Failed to parse MSI GUID. Using raw string." -Level "WARN"
		}
	} else {
		$FinalCmd = $UninstallCmd
	}

	# 2. Write the command natively to a temporary batch file
	Write-EngineLog -Message "Writing final execution string to temporary batch wrapper."
	Set-Content -Path $WrapperScript -Value "@echo off`r`n$FinalCmd" -Encoding ASCII -Force

	# 3. Launch the batch file via ServiceUI
	$SessionArg = "-session:$TargetSession"
	$PInfo = New-Object System.Diagnostics.ProcessStartInfo
	$PInfo.FileName = $ServiceUI
	$PInfo.Arguments = "$SessionArg `"$env:SystemRoot\System32\cmd.exe`" /c `"$WrapperScript`""
	$PInfo.UseShellExecute = $false

	Write-EngineLog -Message "Bridging batch wrapper into user session $TargetSession"
	$Process = [System.Diagnostics.Process]::Start($PInfo)
	$Process.WaitForExit()
	Write-EngineLog -Message "Process finished with Exit Code: $($Process.ExitCode)"

	# 4. Clean up
	Remove-Item -Path $WrapperScript -Force -ErrorAction SilentlyContinue

    Remove-Item -Path $SelectionFile -Force -ErrorAction SilentlyContinue
    Write-EngineLog -Message "Interactive routine for '$AppName' ended." -Level "INFO"

} catch {
    Write-EngineLog -Message "Unhandled error in Engine: $($_.Exception.Message)" -Level "ERROR"
}

'@
    Set-Content -Path $EngineScript -Value $EngineContent -Encoding UTF8 -Force
    Write-AppLog -Message "Engine script written to $EngineScript" -Level INFO

    # 4. GENERATE USER GUI SELECTOR SCRIPT
    $SelectorContent = @'
# ==============================================================================
# Execution Context: Standard User Interactive Session
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$InstallDir    = "$env:ProgramData\AppUninstaller"
$SelectionFile = "$InstallDir\selected_app.json"
$UserLog       = "$InstallDir\Logs\UserGUI.log"

function Write-UserLog {
    param([string]$Message, [string]$Level = "INFO")
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $UserLog -Value "[$TimeStamp] [$Level] $Message" -ErrorAction SilentlyContinue
}

try {
    Write-UserLog -Message "GUI launched by user."

    $UninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "System Application Uninstaller"
    $Form.Size = New-Object System.Drawing.Size(650, 480)
    $Form.StartPosition = "CenterScreen"
    $Form.FormBorderStyle = "FixedDialog"
    $Form.MaximizeBox = $false

    $Grid = New-Object System.Windows.Forms.DataGridView
    $Grid.Size = New-Object System.Drawing.Size(610, 340)
    $Grid.Location = New-Object System.Drawing.Point(12, 12)
    $Grid.SelectionMode = "FullRowSelect"
    $Grid.MultiSelect = $false
    $Grid.AutoSizeColumnsMode = "Fill"
    $Grid.ReadOnly = $true
    $Grid.AllowUserToAddRows = $false

    $Table = New-Object System.Data.DataTable
    $null = $Table.Columns.Add("Application Name")
    $null = $Table.Columns.Add("Version")
    $null = $Table.Columns.Add("Publisher")
    $null = $Table.Columns.Add("UninstallCmd")

    # Initial App Load
    $Apps = Get-ChildItem -Path $UninstallPaths -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ItemProperty -Path $_.PsPath
    } | Where-Object { 
        $_.DisplayName -and $_.UninstallString -and $_.SystemComponent -ne 1 -and $_.ParentKeyName -eq $null
    } | Select-Object DisplayName, DisplayVersion, Publisher, UninstallString | Sort-Object DisplayName

    foreach ($App in $Apps) {
        $null = $Table.Rows.Add($App.DisplayName, $App.DisplayVersion, $App.Publisher, $App.UninstallString)
    }

    $Grid.DataSource = $Table

    if ($Grid.Columns.Count -ge 4) {
        $Grid.Columns[3].Visible = $false
    }

    $Form.Controls.Add($Grid)

    $Button = New-Object System.Windows.Forms.Button
    $Button.Text = "Uninstall Selected Software"
    $Button.Size = New-Object System.Drawing.Size(180, 38)
    $Button.Location = New-Object System.Drawing.Point(225, 370)

    $Button.Add_Click({
        if ($Grid.SelectedRows.Count -gt 0) {
            $SelectedDataRow = $Grid.SelectedRows[0].DataBoundItem.Row
            
            $Name = $SelectedDataRow["Application Name"]
            $Cmd  = $SelectedDataRow["UninstallCmd"]

            if (-not $Name) {
                $Name = $Grid.SelectedRows[0].Cells[0].Value
                $Cmd  = $Grid.SelectedRows[0].Cells[3].Value
            }

            if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($Cmd)) {
                [System.Windows.Forms.MessageBox]::Show("Could not read details for the selected application.", "Error", 'OK', 'Error')
                return
            }

            $Choice = [System.Windows.Forms.MessageBox]::Show(
                "Launch uninstaller for '$Name'?",
                "Confirm Uninstallation",
                'YesNo',
                'Question'
            )

            if ($Choice -eq 'Yes') {
                Write-UserLog -Message "User requested interactive removal of: $Name"
                
                # Capture explicitly current user session ID
                $CurrentSessionId = (Get-Process -Id $PID).SessionId
                $Payload = @{ AppName = [string]$Name; UninstallCommand = [string]$Cmd; SessionId = $CurrentSessionId } | ConvertTo-Json
                [System.IO.File]::WriteAllText($SelectionFile, $Payload, [System.Text.Encoding]::UTF8)

                $Timeout = 0
                while (-not (Test-Path $SelectionFile) -and $Timeout -lt 10) {
                    Start-Sleep -Milliseconds 200
                    $Timeout++
                }

                if (-not (Test-Path $SelectionFile)) {
                    [System.Windows.Forms.MessageBox]::Show("Failed to save selection payload.", "Error", 'OK', 'Error')
                    return
                }

                $Result = Start-Process "schtasks.exe" -ArgumentList "/Run /TN `"IntuneSystemAppUninstaller`"" -Wait -NoNewWindow -PassThru

                if ($Result.ExitCode -eq 0) {
                    # Disable UI interactions and show wait status
                    $Button.Enabled = $false
                    $Button.Text = "Uninstalling..."
                    $Form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

                    # Poll for completion (engine deletes SelectionFile on exit)
                    while (Test-Path $SelectionFile) {
                        Start-Sleep -Milliseconds 500
                        [System.Windows.Forms.Application]::DoEvents()
                    }

                    # Refresh the application list from Registry
                    $Table.Rows.Clear()
                    $RefreshApps = Get-ChildItem -Path $UninstallPaths -ErrorAction SilentlyContinue | ForEach-Object {
                        Get-ItemProperty -Path $_.PsPath
                    } | Where-Object { 
                        $_.DisplayName -and $_.UninstallString -and $_.SystemComponent -ne 1 -and $_.ParentKeyName -eq $null
                    } | Select-Object DisplayName, DisplayVersion, Publisher, UninstallString | Sort-Object DisplayName

                    foreach ($AppItem in $RefreshApps) {
                        $null = $Table.Rows.Add($AppItem.DisplayName, $AppItem.DisplayVersion, $AppItem.Publisher, $AppItem.UninstallString)
                    }

                    # Restore UI state
                    $Button.Enabled = $true
                    $Button.Text = "Uninstall Selected Software"
                    $Form.Cursor = [System.Windows.Forms.Cursors]::Default

                } else {
                    [System.Windows.Forms.MessageBox]::Show("Failed to trigger task. Error Code: $($Result.ExitCode)", "Task Error", 'OK', 'Error')
                }
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please select an application from the list.", "Selection Required", 'OK', 'Warning')
        }
    })

    $Form.Controls.Add($Button)
    $Form.ShowDialog() | Out-Null

} catch {
    Write-UserLog -Message "Error in User GUI: $($_.Exception.Message)" -Level "ERROR"
}
'@
    Set-Content -Path $SelectorScript -Value $SelectorContent -Encoding UTF8 -Force
    Write-AppLog -Message "Selector script written to $SelectorScript" -Level INFO

    # 5. APPLY NTFS SECURITY ACLs
    Write-AppLog -Message "Applying Security ACLs to directory..." -Level INFO
    
    $Acl = Get-Acl $InstallDir
    $Acl.SetAccessRuleProtection($true, $false)

    $SystemRights   = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $AdminRights    = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $UserRights     = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")

    $Acl.AddAccessRule($SystemRights)
    $Acl.AddAccessRule($AdminRights)
    $Acl.AddAccessRule($UserRights)
    Set-Acl -Path $InstallDir -AclObject $Acl

    # 6. REGISTER SCHEDULED TASK AS SYSTEM
    Write-AppLog -Message "Registering Scheduled Task: $TaskName" -Level INFO
    
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
        Write-AppLog -Message "Granted Users execution permissions on task file." -Level INFO
    }

    # 7. CREATE START MENU SHORTCUT
    Write-AppLog -Message "Creating Start Menu Shortcut for Standard Users..." -Level INFO
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -sta -File `"$SelectorScript`""
    $Shortcut.IconLocation = "imageres.dll,89"
    $Shortcut.Description = "Interactively uninstall system-wide software applications."
    $Shortcut.Save()

    Write-AppLog -Message "Deployment completed successfully." -Level INFO
    exit 0

} catch {
    Write-AppLog -Message "Fatal deployment failure: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}
[CmdletBinding()]
param(
    [ValidateSet('Install', 'Uninstall')]
    [string]$Action = 'Install'
)

# --- 1. Relaunch in 64-bit Process if currently in 32-bit ---
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    $ps64Path = Join-Path $env:WinDir "SysNative\WindowsPowerShell\v1.0\powershell.exe"
    $scriptPath = $MyInvocation.MyCommand.Path

    if ($scriptPath) {
        & $ps64Path -NoProfile -ExecutionPolicy Bypass -File $scriptPath @PSBoundParameters
    } else {
        $commandBlock = [scriptblock]::Create($MyInvocation.MyCommand.Definition)
        & $ps64Path -NoProfile -ExecutionPolicy Bypass -Command $commandBlock
    }

    exit $LASTEXITCODE
}

# --- 2. CMTrace Logging Setup ---
$LogDir  = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
$LogFile = Join-Path $LogDir "Script_Deployment.log"

if (-not (Test-Path -Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO',
        [string]$Component = "DeploymentScript"
    )

    # CMTrace Type IDs: 1 = Informational, 2 = Warning (Yellow), 3 = Error (Red)
    $TypeMap = @{ 'INFO' = 1; 'WARNING' = 2; 'ERROR' = 3 }
    $Type = $TypeMap[$Level]

    # Time Metadata
    $Time = Get-Date -Format "HH:mm:ss.fff"
    $Date = Get-Date -Format "MM-dd-yyyy"
    
    # Calculate UTC Bias in Minutes
    $UtcOffset = [TimeZoneInfo]::Local.GetUtcOffset([DateTime]::Now)
    $Bias = [int]$UtcOffset.TotalMinutes

    # Strict Native CMTrace XML Format (No trailing spaces before closing tag)
    $CmtraceFormattedEntry = "<![LOG[$Message]LOG]!><time=""$Time+$Bias"" date=""$Date"" component=""$Component"" context="""" type=""$Type"" thread=""$PID"" file="""">"

    # Display Entry for PowerShell Console Window
    $ConsoleEntry = "[$Date $Time] [$Level] $Message"

    switch ($Level) {
        'WARNING' { Write-Host $ConsoleEntry -ForegroundColor Yellow }
        'ERROR'   { Write-Host $ConsoleEntry -ForegroundColor Red }
        Default   { Write-Host $ConsoleEntry -ForegroundColor Cyan }
    }

    # Write as ASCII / Default to avoid UTF-8 BOM parsing glitches in CMTrace
    Out-File -FilePath $LogFile -InputObject $CmtraceFormattedEntry -Append -Encoding ascii -ErrorAction SilentlyContinue
}

# --- 3. Main Script Logic ---
$arch = if ([Environment]::Is64BitProcess) { "64-bit" } else { "32-bit" }

Write-Log -Message "Script execution initiated."
Write-Log -Message "Process Architecture: $arch"
Write-Log -Message "Requested Action: $Action"

switch ($Action) {
    'Install' {
        Write-Log -Message "Starting installation routines..."
        # Insert installation commands here
        Write-Log -Message "Installation completed successfully."
    }
    'Uninstall' {
        Write-Log -Message "Starting uninstallation routines..."
        # Insert uninstallation commands here
        Write-Log -Message "Uninstallation completed successfully."
    }
}
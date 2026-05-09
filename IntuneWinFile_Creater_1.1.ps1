<#
.SYNOPSIS
Automatically creates an IntuneWin package using IntuneWinAppUtil.exe.

.DESCRIPTION
This script:
- Works properly after PS2EXE conversion
- Detects IntuneWinAppUtil.exe
- Uses fixed project structure
- Detects setup installer automatically
- Removes old IntuneWin package
- Creates new IntuneWin package
- Provides enterprise-style logging

.REQUIRED STRUCTURE

ProjectFolder
│
├── Tools
│   ├── Intune-Packager.exe
│   └── IntuneWinAppUtil.exe
│
├── Application
│   └── setup.exe / install.ps1 / app.msi
│
└── Intune

.AUTHOR
Arghya Biswas
#>

# =========================
# LOGGING FUNCTION
# =========================

function Write-Log {

    param (
        [string]$Message,

        [ValidateSet("INFO","SUCCESS","WARNING","ERROR")]
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    switch ($Level) {

        "INFO"    { $Color = "Cyan" }
        "SUCCESS" { $Color = "Green" }
        "WARNING" { $Color = "Yellow" }
        "ERROR"   { $Color = "Red" }
    }

    Write-Host "[$Timestamp] [$Level] $Message" -ForegroundColor $Color
}

# =========================
# SCRIPT START
# =========================

Clear-Host

Write-Log "==================================================" "INFO"
Write-Log "        INTUNE PACKAGE CREATION TOOLKIT           " "INFO"
Write-Log "==================================================" "INFO"

# =========================
# GET CURRENT DIRECTORY
# =========================

try {

    # EXE SAFE METHOD
    $CurrentDir = [System.IO.Path]::GetDirectoryName(
        [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    )

    if ([string]::IsNullOrWhiteSpace($CurrentDir)) {

        throw "Current directory returned NULL."
    }

    Write-Log "Current directory detected." "SUCCESS"

    Write-Host ""
    Write-Host "Current Directory:" -ForegroundColor Cyan
    Write-Host "  $CurrentDir" -ForegroundColor White
}
catch {

    Write-Log "Failed to determine current directory." "ERROR"
    Write-Log $_.Exception.Message "ERROR"

    exit 1
}

# =========================
# TOOL PATHS
# =========================

$IntuneUtil = Join-Path $CurrentDir "IntuneWinAppUtil.exe"

if (-not (Test-Path $IntuneUtil)) {

    Write-Log "IntuneWinAppUtil.exe not found." "ERROR"

    Write-Host ""
    Write-Host "Expected Location:" -ForegroundColor Yellow
    Write-Host "  $IntuneUtil" -ForegroundColor White

    exit 1
}

Write-Log "IntuneWinAppUtil.exe found successfully." "SUCCESS"

# =========================
# ROOT FOLDER
# =========================

$RootFolder = Split-Path $CurrentDir -Parent

Write-Host ""
Write-Host "Root Project Folder:" -ForegroundColor Cyan
Write-Host "  $RootFolder" -ForegroundColor White

# =========================
# APPLICATION FOLDER
# =========================

$ApplicationFolder = Join-Path $RootFolder "Application"

if (-not (Test-Path $ApplicationFolder)) {

    Write-Log "'Application' folder not found." "ERROR"

    Write-Host ""
    Write-Host "Expected Location:" -ForegroundColor Yellow
    Write-Host "  $ApplicationFolder" -ForegroundColor White

    exit 1
}

Write-Log "'Application' folder found." "SUCCESS"

# =========================
# INTUNE FOLDER
# =========================

$IntuneFolder = Join-Path $RootFolder "Intune"

if (-not (Test-Path $IntuneFolder)) {

    Write-Log "'Intune' folder does not exist. Creating..." "WARNING"

    try {

        New-Item `
            -Path $IntuneFolder `
            -ItemType Directory `
            -Force | Out-Null

        Write-Log "'Intune' folder created successfully." "SUCCESS"
    }
    catch {

        Write-Log "Failed to create Intune folder." "ERROR"
        Write-Log $_.Exception.Message "ERROR"

        exit 1
    }
}
else {

    Write-Log "Using existing 'Intune' folder." "INFO"
}

# =========================
# SEARCH INSTALLER
# =========================

Write-Log "Searching for setup file..." "INFO"

$SupportedExtensions = @(
    ".exe",
    ".msi",
    ".ps1",
    ".bat",
    ".cmd"
)

$SetupFile = Get-ChildItem `
    -Path $ApplicationFolder `
    -File |
    Where-Object {
        $_.Extension.ToLower() -in $SupportedExtensions
    } |
    Sort-Object Name |
    Select-Object -First 1

if (-not $SetupFile) {

    Write-Log "No supported setup file found." "ERROR"

    Write-Host ""
    Write-Host "Supported Extensions:" -ForegroundColor Yellow
    Write-Host "  .exe .msi .ps1 .bat .cmd" -ForegroundColor White

    exit 1
}

Write-Log "Setup file detected successfully." "SUCCESS"

Write-Host ""
Write-Host "Setup File:" -ForegroundColor Cyan
Write-Host "  $($SetupFile.Name)" -ForegroundColor White

# =========================
# REMOVE OLD PACKAGE
# =========================

$IntuneWinName = "$($SetupFile.BaseName).intunewin"

$IntuneWinFile = Join-Path $IntuneFolder $IntuneWinName

if (Test-Path $IntuneWinFile) {

    Write-Log "Existing IntuneWin package detected." "WARNING"

    Write-Host ""
    Write-Host "Removing Old Package:" -ForegroundColor Yellow
    Write-Host "  $IntuneWinFile" -ForegroundColor White

    try {

        Remove-Item `
            -Path $IntuneWinFile `
            -Force `
            -ErrorAction Stop

        Write-Log "Old package removed successfully." "SUCCESS"
    }
    catch {

        Write-Log "Failed to remove existing package." "ERROR"
        Write-Log $_.Exception.Message "ERROR"

        exit 1
    }
}
else {

    Write-Log "No previous IntuneWin package found." "INFO"
}

# =========================
# BUILD ARGUMENTS
# =========================

$Arguments = @(
    "-c", "`"$ApplicationFolder`"",
    "-s", "`"$($SetupFile.Name)`"",
    "-o", "`"$IntuneFolder`"",
    "-q"
)

# =========================
# PACKAGE SUMMARY
# =========================

Write-Host ""
Write-Host "==================================================" -ForegroundColor DarkGray
Write-Host "PACKAGE SUMMARY" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor DarkGray

Write-Host "Source Folder :" -ForegroundColor Yellow
Write-Host "  $ApplicationFolder" -ForegroundColor White

Write-Host ""
Write-Host "Setup File :" -ForegroundColor Yellow
Write-Host "  $($SetupFile.Name)" -ForegroundColor White

Write-Host ""
Write-Host "Output Folder :" -ForegroundColor Yellow
Write-Host "  $IntuneFolder" -ForegroundColor White

Write-Host ""
Write-Host "Output Package :" -ForegroundColor Yellow
Write-Host "  $IntuneWinName" -ForegroundColor White

Write-Host ""
Write-Host "==================================================" -ForegroundColor DarkGray

# =========================
# START PACKAGING
# =========================

Write-Log "Launching IntuneWinAppUtil.exe..." "INFO"

try {

    $Process = Start-Process `
        -FilePath $IntuneUtil `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru `
        -NoNewWindow

    if ($Process.ExitCode -eq 0) {

        Write-Host ""

        Write-Log "Intune package created successfully." "SUCCESS"

        Write-Host ""
        Write-Host "Generated Package:" -ForegroundColor Green
        Write-Host "  $IntuneWinFile" -ForegroundColor White
    }
    else {

        Write-Log "IntuneWinAppUtil.exe failed." "ERROR"

        Write-Host ""
        Write-Host "Exit Code:" -ForegroundColor Yellow
        Write-Host "  $($Process.ExitCode)" -ForegroundColor White

        exit $Process.ExitCode
    }
}
catch {

    Write-Log "Failed to execute IntuneWinAppUtil.exe." "ERROR"
    Write-Log $_.Exception.Message "ERROR"

    exit 1
}

# =========================
# COMPLETE
# =========================

Write-Host ""
Write-Host "==================================================" -ForegroundColor DarkGray

Write-Log "SCRIPT COMPLETED SUCCESSFULLY" "SUCCESS"

Write-Host "==================================================" -ForegroundColor DarkGray
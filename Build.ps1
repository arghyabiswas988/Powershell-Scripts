<#
.SYNOPSIS
Creates a professional Intune Packaging Toolkit folder structure.

.DESCRIPTION
This script creates an enterprise-style folder structure
without creating the following folders:

- Application
- Intune
- Dev
- Documentation
- Source
- Scripts

.AUTHOR
Arghya Biswas
#>

# =========================
# LOGGING FUNCTION
# =========================
function Write-Log {
    param (
        [string]$Message,

        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
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
Write-Log "========== TOOLKIT STRUCTURE CREATION =========="

# Ask for project name
$ProjectName = Read-Host "Enter Project Name"

if ([string]::IsNullOrWhiteSpace($ProjectName)) {

    Write-Log "Project name cannot be empty." "ERROR"
    exit 1
}

# Base path
$BasePath = Join-Path "C:\Temp" $ProjectName

Write-Log "Base project path: $BasePath"

# Folder structure
$Folders = @(
    "Build",
    "Tools",
    "Output",
    "Logs",
    "Assets",
    "Config",
    "Modules",
    "Templates"
)

# Files to create
$Files = @(
    "Build\Build-EXE.ps1",
    "Build\Version.txt",
    "Config\Config.json",
    "README.md"
)

# =========================
# CREATE BASE DIRECTORY
# =========================
try {

    if (-not (Test-Path $BasePath)) {

        New-Item -Path $BasePath -ItemType Directory -Force | Out-Null

        Write-Log "Created project root folder." "SUCCESS"
    }
    else {

        Write-Log "Project root folder already exists." "WARNING"
    }
}
catch {

    Write-Log "Failed to create base folder." "ERROR"
    Write-Log $_.Exception.Message "ERROR"

    exit 1
}

# =========================
# CREATE FOLDERS
# =========================
Write-Log "Creating folder structure..."

foreach ($Folder in $Folders) {

    $FullPath = Join-Path $BasePath $Folder

    try {

        if (-not (Test-Path $FullPath)) {

            New-Item -Path $FullPath -ItemType Directory -Force | Out-Null

            Write-Log "Created folder: $Folder" "SUCCESS"
        }
        else {

            Write-Log "Folder already exists: $Folder" "WARNING"
        }
    }
    catch {

        Write-Log "Failed to create folder: $Folder" "ERROR"
        Write-Log $_.Exception.Message "ERROR"
    }
}

# =========================
# CREATE FILES
# =========================
Write-Log "Creating starter files..."

foreach ($File in $Files) {

    $FilePath = Join-Path $BasePath $File

    try {

        if (-not (Test-Path $FilePath)) {

            New-Item -Path $FilePath -ItemType File -Force | Out-Null

            Write-Log "Created file: $File" "SUCCESS"
        }
        else {

            Write-Log "File already exists: $File" "WARNING"
        }
    }
    catch {

        Write-Log "Failed to create file: $File" "ERROR"
        Write-Log $_.Exception.Message "ERROR"
    }
}

# =========================
# ADD DEFAULT CONTENT
# =========================

# Version.txt
$VersionFile = Join-Path $BasePath "Build\Version.txt"

@"
1.0.0
"@ | Set-Content $VersionFile

# README.md
$ReadmeFile = Join-Path $BasePath "README.md"

@"
# Intune Packaging Toolkit

## Description
Professional Microsoft Intune Packaging Toolkit.

## Author
Arghya Biswas

## Version
1.0.0
"@ | Set-Content $ReadmeFile

# Config.json
$ConfigFile = Join-Path $BasePath "Config\Config.json"

@"
{
    "CompanyName": "Your Company",
    "ProductName": "Intune Packaging Toolkit",
    "Version": "1.0.0"
}
"@ | Set-Content $ConfigFile

Write-Log "Default configuration files created." "SUCCESS"

# =========================
# COMPLETE
# =========================
Write-Log "========== STRUCTURE CREATION COMPLETED ==========" "SUCCESS"

Write-Log "Project Location:" "INFO"
Write-Host $BasePath -ForegroundColor Green
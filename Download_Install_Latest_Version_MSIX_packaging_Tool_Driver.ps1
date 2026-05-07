<#
.SYNOPSIS
Installs MSIX Packaging Tool and driver package using SYSTEM account.

.DESCRIPTION
This script:
1. Installs MSIX Packaging Tool using winget.
2. Downloads the MSIX Packaging Tool driver CAB package.
3. Installs the CAB package using DISM.

.AUTHOR
Arghya Biswas
#>

# ==============================
# Variables
# ==============================
$WingetId = "9N5LW3JBCXKF"

$DriverUrl = "https://download.microsoft.com/download/6/c/7/6c7d654b-580b-40d4-8502-f8d435ca125a/Msix-PackagingTool-Driver-Package%7E31bf3856ad364e35%7Eamd64%7E%7E.cab"

$DownloadFolder = "C:\Temp\MSIXPackagingTool"
$CabFile = Join-Path $DownloadFolder "MSIXPackagingToolDriver.cab"

# ==============================
# Create Download Folder
# ==============================
if (-not (Test-Path $DownloadFolder)) {
    New-Item -Path $DownloadFolder -ItemType Directory -Force | Out-Null
}

# ==============================
# Locate Winget
# ==============================
Write-Host "Locating winget..." -ForegroundColor Cyan

$WingetPath = Get-ChildItem `
    -Path "C:\Program Files\WindowsApps" `
    -Filter "winget.exe" `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $WingetPath) {
    Write-Host "winget.exe not found." -ForegroundColor Red
    exit 1
}

Write-Host "Winget found at: $WingetPath" -ForegroundColor Green

# ==============================
# Install MSIX Packaging Tool
# ==============================
Write-Host "Installing MSIX Packaging Tool..." -ForegroundColor Cyan

try {
    $WingetArgs = @(
        "install"
        "--id", $WingetId
        "--exact"
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--silent"
    )

    $Process = Start-Process -FilePath $WingetPath -ArgumentList $WingetArgs -Wait -PassThru -NoNewWindow

    if ($Process.ExitCode -ne 0) {
        throw "Winget installation failed with exit code $($Process.ExitCode)"
    }

    Write-Host "MSIX Packaging Tool installed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to install MSIX Packaging Tool." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
<#
# ==============================
# Download Driver CAB File
# ==============================
Write-Host "Downloading driver package..." -ForegroundColor Cyan

try {
    Invoke-WebRequest `
        -Uri $DriverUrl `
        -OutFile $CabFile `
        -UseBasicParsing

    if (-not (Test-Path $CabFile)) {
        throw "Driver CAB file was not downloaded."
    }

    Write-Host "Driver package downloaded successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to download driver package." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
#>

# ==============================
# Install MSIX Packaging Tool Driver
# ==============================
Write-Host "Installing MSIX Packaging Tool driver..." -ForegroundColor Cyan

try {
    $Process = Start-Process `
        -FilePath "dism.exe" `
        -ArgumentList '/Online /Add-Capability /CapabilityName:Msix.PackagingTool.Driver~~~~0.0.1.0' `
        -Wait `
        -PassThru `
        -NoNewWindow

    if ($Process.ExitCode -ne 0) {
        throw "DISM failed with exit code $($Process.ExitCode)"
    }

    Write-Host "MSIX Packaging Tool driver installed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to install MSIX Packaging Tool driver." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host ""
Write-Host "All operations completed successfully." -ForegroundColor Green

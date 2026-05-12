<#
.SYNOPSIS
Automatically creates an IntuneWin package using IntuneWinAppUtil.exe.

.DESCRIPTION
This script checks if IntuneWinAppUtil.exe exists in the current directory.
If found, it moves to the parent folder, searches for the "Application" folder,
detects an installer/script file inside it, and runs IntuneWinAppUtil.exe.

Supported setup files:
- .exe
- .msi
- .ps1
- .bat
- .cmd

Output will be saved in the "Intune" folder located beside the "Application" folder.

.AUTHOR
Arghya Biswas
#>

# Get current script directory
$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Path to IntuneWinAppUtil.exe
$IntuneUtil = Join-Path $CurrentDir "IntuneWinAppUtil.exe"

# Check if IntuneWinAppUtil.exe exists
if (-not (Test-Path $IntuneUtil)) {
    Write-Host "ERROR: IntuneWinAppUtil.exe not found in:" -ForegroundColor Red
    Write-Host $CurrentDir -ForegroundColor Yellow
    exit 1
}

Write-Host "Found IntuneWinAppUtil.exe" -ForegroundColor Green

# Move to parent folder
$ParentFolder = Split-Path $CurrentDir -Parent

Write-Host "Searching under parent folder:" -ForegroundColor Cyan
Write-Host $ParentFolder

# Search for Application folder
$ApplicationFolder = Get-ChildItem -Path $ParentFolder -Directory -Recurse |
    Where-Object { $_.Name -eq "Application" } |
    Select-Object -First 1

if (-not $ApplicationFolder) {
    Write-Host "ERROR: Application folder not found." -ForegroundColor Red
    exit 1
}

Write-Host "Found Application folder:" -ForegroundColor Green
Write-Host $ApplicationFolder.FullName

# Search for supported setup files
$SetupFile = Get-ChildItem -Path $ApplicationFolder.FullName -File |
    Where-Object {
        $_.Extension -in @(".exe", ".msi", ".ps1", ".bat", ".cmd")
    } |
    Select-Object -First 1

if (-not $SetupFile) {
    Write-Host "ERROR: No supported installer/script found in Application folder." -ForegroundColor Red
    exit 1
}

Write-Host "Found setup file:" -ForegroundColor Green
Write-Host $SetupFile.FullName

# Check for Intune folder at same level as Application folder
$BaseFolder = Split-Path $ApplicationFolder.FullName -Parent
$IntuneFolder = Join-Path $BaseFolder "Intune"

# Create Intune folder if missing
if (-not (Test-Path $IntuneFolder)) {
    Write-Host "Intune folder not found. Creating..." -ForegroundColor Yellow

    New-Item -Path $IntuneFolder -ItemType Directory -Force | Out-Null
}

Write-Host "Using output folder:" -ForegroundColor Green
Write-Host $IntuneFolder

# Build command arguments
$Arguments = @(
    "-c", "`"$($ApplicationFolder.FullName)`"",
    "-s", "`"$($SetupFile.Name)`"",
    "-o", "`"$IntuneFolder`"",
    "-q"
)

Write-Host "`nExecuting IntuneWinAppUtil.exe..." -ForegroundColor Cyan
Write-Host "$IntuneUtil $($Arguments -join ' ')" -ForegroundColor Yellow

# Execute IntuneWinAppUtil.exe
Start-Process -FilePath $IntuneUtil `
    -ArgumentList $Arguments `
    -Wait `
    -NoNewWindow

Write-Host "`nIntune package creation completed." -ForegroundColor Green
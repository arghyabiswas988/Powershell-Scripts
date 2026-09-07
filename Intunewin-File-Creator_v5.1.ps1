<#
.SYNOPSIS
    Packages an Intune Win32 app using IntuneWinAppUtil.exe.
    - Finds setup files in <Parent>\Application (Priority: .ps1 > .bat > .msi > .exe)
    - Sets <Parent>\Application as the source folder
    - Outputs and rev-increments in <Parent>\Intune
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# -------------------------------------------------------------------------
# Step 1: Locate or Download IntuneWinAppUtil.exe
# -------------------------------------------------------------------------
$ExeName = "IntuneWinAppUtil.exe"
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) {
    $ScriptDir = (Get-Location).Path
}

$ExePath = $null

# Check environment PATH
$EnvCommand = Get-Command $ExeName -ErrorAction SilentlyContinue
if ($EnvCommand) {
    $ExePath = $EnvCommand.Source
    Write-Host "[INFO] Found $ExeName in PATH: $ExePath" -ForegroundColor Green
}
# Check script directory
elseif (Test-Path (Join-Path $ScriptDir $ExeName)) {
    $ExePath = Join-Path $ScriptDir $ExeName
    Write-Host "[INFO] Found $ExeName in script folder: $ExePath" -ForegroundColor Green
}
# Download from official Microsoft repo
else {
    Write-Host "[INFO] $ExeName not found. Downloading latest release from GitHub..." -ForegroundColor Yellow
    $TargetDownloadPath = Join-Path $ScriptDir $ExeName
    $DownloadUrl = "https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/IntuneWinAppUtil.exe"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $TargetDownloadPath -UseBasicParsing
        $ExePath = $TargetDownloadPath
        Write-Host "[INFO] Successfully downloaded $ExeName to $ExePath" -ForegroundColor Green
    }
    catch {
        throw ("Failed to download " + $ExeName + " - " + $_.Exception.Message)
    }
}

# -------------------------------------------------------------------------
# Step 2: Resolve Directory Structure & Detect Setup File
# -------------------------------------------------------------------------
$ParentDirItem = (Get-Item $ScriptDir).Parent
if (-not $ParentDirItem) {
    throw "Cannot determine parent directory from: $ScriptDir"
}

$ParentDirName = $ParentDirItem.Name
$ParentDirPath = $ParentDirItem.FullName

# Target 'Application' folder as the source directory
$SourceFolder = Join-Path $ParentDirPath "Application"

if (-not (Test-Path $SourceFolder)) {
    throw "The required 'Application' folder does not exist at: $SourceFolder"
}

# Supported file extensions in order of evaluation
$SupportedExtensions = @(".ps1", ".bat", ".msi", ".exe")
$InstallerFiles = Get-ChildItem -Path $SourceFolder -File | Where-Object { $_.Extension -in $SupportedExtensions }

if ($InstallerFiles.Count -eq 0) {
    throw "No .ps1, .bat, .msi, or .exe file found in: $SourceFolder"
}

# Select first matching file according to defined precedence (.ps1 -> .bat -> .msi -> .exe)
$SelectedInstaller = $null
foreach ($ext in $SupportedExtensions) {
    $SelectedInstaller = $InstallerFiles | Where-Object { $_.Extension -eq $ext } | Select-Object -First 1
    if ($SelectedInstaller) {
        break
    }
}

$SetupFile = $SelectedInstaller.Name

Write-Host "[INFO] Parent App Name: $ParentDirName" -ForegroundColor Cyan
Write-Host "[INFO] Source Folder  : $SourceFolder" -ForegroundColor Cyan
Write-Host "[INFO] Setup File     : $SetupFile" -ForegroundColor Cyan

# Output directory: <Parent>\Intune
$OutputDir = Join-Path $ParentDirPath "Intune"
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    Write-Host "[INFO] Created output folder: $OutputDir" -ForegroundColor Green
}

# -------------------------------------------------------------------------
# Step 3: Determine Destination Filename (Revision Increments)
# -------------------------------------------------------------------------
$BaseName = $ParentDirName
$TargetFileName = "$BaseName.intunewin"
$FinalTargetPath = Join-Path $OutputDir $TargetFileName

if (Test-Path $FinalTargetPath) {
    $RevIndex = 2
    do {
        $FormattedRev = "{0:D2}" -f $RevIndex
        $TargetFileName = "${BaseName}_Rev${FormattedRev}.intunewin"
        $FinalTargetPath = Join-Path $OutputDir $TargetFileName
        $RevIndex++
    } while (Test-Path $FinalTargetPath)
}

Write-Host "[INFO] Target Package : $TargetFileName" -ForegroundColor Cyan

# -------------------------------------------------------------------------
# Step 4: Run IntuneWinAppUtil.exe & Rename Output
# -------------------------------------------------------------------------
$ProcessArgs = @(
    "-c", "`"$SourceFolder`"",
    "-s", "`"$SetupFile`"",
    "-o", "`"$OutputDir`"",
    "-q"
)

Write-Host "[INFO] Executing Intune packaging process..." -ForegroundColor Yellow
$Process = Start-Process -FilePath $ExePath -ArgumentList $ProcessArgs -Wait -NoNewWindow -PassThru

if ($Process.ExitCode -ne 0) {
    throw "Intune packaging failed with exit code $($Process.ExitCode)"
}

# IntuneWinAppUtil creates the file named after the setup file: <SetupFileNameWithoutExt>.intunewin
$DefaultGeneratedName = [System.IO.Path]::GetFileNameWithoutExtension($SetupFile) + ".intunewin"
$DefaultGeneratedPath = Join-Path $OutputDir $DefaultGeneratedName

if (Test-Path $DefaultGeneratedPath) {
    Rename-Item -Path $DefaultGeneratedPath -NewName $TargetFileName -Force
    Write-Host "[SUCCESS] Package generated and renamed to: $FinalTargetPath" -ForegroundColor Green
}
else {
    $RecentFile = Get-ChildItem -Path $OutputDir -Filter "*.intunewin" | 
                  Sort-Object LastWriteTime -Descending | 
                  Select-Object -First 1

    if ($RecentFile -and $RecentFile.FullName -ne $FinalTargetPath) {
        Rename-Item -Path $RecentFile.FullName -NewName $TargetFileName -Force
        Write-Host "[SUCCESS] Package generated and renamed to: $FinalTargetPath" -ForegroundColor Green
    }
    else {
        throw "Packaging complete, but generated output file was not found in $OutputDir."
    }
}

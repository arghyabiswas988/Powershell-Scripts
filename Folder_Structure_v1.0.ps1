<#
.SYNOPSIS
Creates a project folder structure under C:\Temp.

.DESCRIPTION
This script asks the user for a folder name, creates it under C:\Temp,
and then creates the following subfolders inside it:

- Application
- Intune
- Dev
- Documentation
- Source
- Scripts

.AUTHOR
Arghya Biswas
#>

# Ask user for folder name
$FolderName = Read-Host "Enter the main folder name"

# Base path
$BasePath = "C:\Temp\$FolderName"

# List of subfolders
$SubFolders = @(
    "Application",
    "Intune",
    "Dev",
    "Documentation",
    "Source",
    "Scripts"
)

try {
    # Create main folder
    if (-not (Test-Path $BasePath)) {
        New-Item -Path $BasePath -ItemType Directory -Force | Out-Null
        Write-Host "Created main folder: $BasePath" -ForegroundColor Green
    }
    else {
        Write-Host "Main folder already exists: $BasePath" -ForegroundColor Yellow
    }

    # Create subfolders
    foreach ($Folder in $SubFolders) {
        $FullPath = Join-Path $BasePath $Folder

        if (-not (Test-Path $FullPath)) {
            New-Item -Path $FullPath -ItemType Directory -Force | Out-Null
            Write-Host "Created subfolder: $FullPath" -ForegroundColor Cyan
        }
        else {
            Write-Host "Subfolder already exists: $FullPath" -ForegroundColor Yellow
        }
    }

    Write-Host "`nFolder structure creation completed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
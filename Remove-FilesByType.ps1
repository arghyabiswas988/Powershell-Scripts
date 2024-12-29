# Define the function
function Remove-FilesByType {
    param (
        [string]$folderPath,
        [string]$fileType
    )

    # Construct the file filter
    $fileFilter = "*.$fileType"

    # Get all files of the specified type recursively
    $files = Get-ChildItem -Path $folderPath -Recurse -Filter $fileFilter

    # Delete each file found
    foreach ($file in $files) {
        Remove-Item -Path $file.FullName -Force
        Write-Host "Deleted $($file.FullName)"
    }

    Write-Host "All $fileType files have been deleted."
}

# Call the function with the folder path and file type
Remove-FilesByType -folderPath "C:\Path\To\Your\Folder" -fileType "json"

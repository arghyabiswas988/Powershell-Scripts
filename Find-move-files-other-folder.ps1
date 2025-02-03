# Define source and destination folders
$sourceFolder = "<Source>"
$destinationFolder = "<destination>"
# Define the word to search for in filenames
$wordToSearch = "word"

# Create destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder
}

# Get files containing the word in their filename and move them
Get-ChildItem -Path $sourceFolder -Filter "*$wordToSearch*" | ForEach-Object {
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $_.Name
    Move-Item -Path $_.FullName -Destination $destinationPath
}#>

Write-Output "Files containing the word '$wordToSearch' in their filenames have been moved to '$destinationFolder'."

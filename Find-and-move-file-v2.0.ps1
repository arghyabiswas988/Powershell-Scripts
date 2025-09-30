# Define source and destination folders
$SourceFolder = "<SourceFolder>"
$DestinationFolder = "<DestinationFolder>"

# Define the search pattern (wildcards allowed)
$SearchPattern = "*user*name*"

# Start timer
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Create destination folder if it doesn't exist
if (!(Test-Path -Path $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
}

# Initialize counters
$FoundCount = 0
$MovedCount = 0
$FailedCount = 0

# Search and attempt to move files
$Files = Get-ChildItem -Path $SourceFolder -File -Recurse | Where-Object { $_.Name -like $SearchPattern }

$FoundCount = $Files.Count

foreach ($File in $Files) {
    try {
        $TargetPath = Join-Path -Path $DestinationFolder -ChildPath $File.Name
        Move-Item -Path $File.FullName -Destination $TargetPath -Force -ErrorAction Stop
        $MovedCount++
        Write-Output "Moved: $($File.FullName) -> $TargetPath"
    }
    catch {
        $FailedCount++
        Write-Output "❌ Failed to move: $($File.FullName) | Error: $($_.Exception.Message)"
    }
}

# Stop timer
$Stopwatch.Stop()

# Show summary
Write-Host ""
Write-Host "===== Summary =====" -ForegroundColor Cyan
Write-Host "Files found      : $FoundCount" -ForegroundColor Yellow
Write-Host "Files moved      : $MovedCount" -ForegroundColor Green
Write-Host "Files failed     : $FailedCount" -ForegroundColor Red
Write-Host "Total time taken : $($Stopwatch.Elapsed.ToString())"
Write-Host "==================="

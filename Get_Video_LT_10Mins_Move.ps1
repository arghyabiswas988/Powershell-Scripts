# Path to the folder containing video files
$sourceFolderPath = "Video Source"
# Path to the destination folder for shorter videos
$destinationFolderPath = "Video destination"

# Get all video files in the source folder
$videoFiles = Get-ChildItem -Path $sourceFolderPath -File | Where-Object {$_.Extension -in @(".mp4", ".avi", ".mov", ".mkv", ".wmv", ".ts")}

# Loop through each video file
foreach ($file in $videoFiles) {
    # Use ffprobe (part of FFmpeg) to get the duration of the video
    $durationOutput = ffmpeg.exe -i "$($file.FullName)" 2>&1 | Select-String -Pattern "Duration"

    # Extract duration string
    $durationString = $durationOutput -replace ".*Duration: ([^,]+).*", '$1'

    # Attempt to parse the duration string
    try {
        # Convert duration string to TimeSpan
        $duration = [TimeSpan]::Parse($durationString)

        # Check if duration is less than 10 minutes
        if ($duration.TotalMinutes -lt 10) {
            # Format the duration as HH:mm
            $formattedDuration = '{0:hh\:mm\:ss}' -f $duration
            # Output the file name and formatted duration
            Write-Host "Moving $($file.Name) - $formattedDuration" # to $destinationFolderPath"
            # Move the file to the destination folder
            Move-Item -Path $file.FullName -Destination $destinationFolderPath -Force
        }
    } catch {
        Write-Host "Error parsing duration for $($file.Name)"
    }
}

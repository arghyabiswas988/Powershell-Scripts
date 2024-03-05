function Get-UserIDFromLogFile {
    param (
        [string[]]$LogFilePaths
    )

    # Define the pattern
    $Pattern = 'ESPPreparation starts for userid: (\w{8}-\w{4}-\w{4}-\w{4}-\w{12})'

    foreach ($LogFilePath in $LogFilePaths) {
        # Check if the log file exists
        if (-not (Test-Path -Path $LogFilePath -PathType Leaf)) {
            Write-Host "Log file not found: $LogFilePath"
            continue
        }

        # Search for the pattern in the log file
        $userIDMatch = Select-String -Path $LogFilePath -Pattern $Pattern -AllMatches

        # Check if a match is found
        if ($userIDMatch.Matches.Count -gt 0) {
            $userID = $userIDMatch.Matches[0].Groups[1].Value
            Write-Output $userID
            return  # Exit the function after finding the first match
        }
    }

    Write-Host "UserID not found in any of the log files."
}

# Example usage:
# Replace the paths with the actual paths to your log files
$LogFiles = @(
    'C:\Path\To\Your\Log\File1.log',
    'C:\Path\To\Your\Log\File2.log',
    'C:\Path\To\Your\Log\File3.log',
    'C:\Path\To\Your\Log\File4.log'
)

Get-UserIDFromLogFile -LogFilePaths $LogFiles

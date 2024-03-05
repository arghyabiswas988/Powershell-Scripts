function Get-UserIDFromLogFile {
    param (
        [string]$LogFilePath
    )

    # Check if the log file exists
    if (-not (Test-Path -Path $LogFilePath -PathType Leaf)) {
        Write-Host "Log file not found: $LogFilePath"
        return
    }

    # Define the pattern
    $Pattern = 'ESPPreparation starts for userid: (\w{8}-\w{4}-\w{4}-\w{4}-\w{12})'

    # Search for the pattern in the log file
    $userIDMatch = Select-String -Path $LogFilePath -Pattern $Pattern -AllMatches

    # Check if a match is found
    if ($userIDMatch.Matches.Count -gt 0) {
        $userID = $userIDMatch.Matches[0].Groups[1].Value
        Write-Output $userID
    } else {
        Write-Host "UserID not found in the log file."
    }
}

# Example usage:
# Replace 'C:\Path\To\Your\Log\File.log' with the actual path to your log file
Get-UserIDFromLogFile -LogFilePath 'C:\Path\To\Your\Log\File.log'

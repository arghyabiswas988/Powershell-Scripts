function Get-UserIDFromLogFile {
    param (
        [string]$LogFilePath
    )

    # Check if the log file exists
    if (-not (Test-Path -Path $LogFilePath -PathType Leaf)) {
        Write-Host "Log file not found: $LogFilePath"
        return
    }

    # Read the content of the log file
    $logContent = Get-Content -Path $LogFilePath -Raw

    # Search for the pattern
    $userIDPattern = "ESPPreparation starts for userid: (\w{8}-\w{4}-\w{4}-\w{4}-\w{12})"
    $userIDMatch = [regex]::Match($logContent, $userIDPattern)

    # Check if a match is found
    if ($userIDMatch.Success) {
        $userID = $userIDMatch.Groups[1].Value
        Write-Output $userID
    } else {
        Write-Host "UserID not found in the log file."
    }
}

# Example usage:
# Replace 'C:\Path\To\Your\Log\File.log' with the actual path to your log file
Get-UserIDFromLogFile -LogFilePath 'C:\Path\To\Your\Log\File.log'

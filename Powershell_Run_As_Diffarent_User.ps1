# Prefill username
$username = "desktop-msi02\Punisher"

# Prompt for credentials
$cred = Get-Credential -UserName $username -Message "Enter password for $username"

# Command to run inside the new session
$command = "Start-Process powershell_ise.exe; Start-Process powershell.exe -Verb RunAs"

# Encode command for safe execution
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encoded = [Convert]::ToBase64String($bytes)

# Start PowerShell as Desktop\User1 and run the commands
Start-Process powershell.exe `
    -Credential $cred `
    -ArgumentList "-NoProfile -EncodedCommand $encoded"
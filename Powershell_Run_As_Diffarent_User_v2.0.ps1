# Prefill username
$username = "desktop-msi02\Punisher"

# Prompt for credentials
$cred = Get-Credential -UserName $username -Message "Enter password for $username"

# Commands to run as the alternate user
$command = @"
\$ise = Start-Process powershell_ise.exe -PassThru
Start-Sleep -Seconds 2
Start-Process powershell.exe -Verb RunAs
Stop-Process -Id \$ise.Id
"@

# Encode command
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encoded = [Convert]::ToBase64String($bytes)

# Run under the alternate credentials
Start-Process powershell.exe `
    -Credential $cred `
    -ArgumentList "-NoProfile -EncodedCommand $encoded"
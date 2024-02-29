
#"<Enter someting here>" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File $Temp\Test.txt
$logpath = "<Log folder location>\Packager"
If (!(test-path $logpath)){
New-Item -ItemType Directory -Path $logpath -Force
}
$PackagerScript = "$logpath\packager.ps1"
$RunmeVBS = "$logpath\RunMe_packager.vbs"
$TempFolder = "C:\Windows\Temp"
$TempFile = Join-Path $TempFolder "<File name>.tmp"

New-Item -Path "$TempFile" -ItemType File -Force
New-Item -Path "$PackagerScript" -ItemType File -Force

$TempFileContent = @'
<Encrypted data here>
'@

$TempFileContent | Out-File -FilePath $TempFile -Encoding utf8

Write-Host "Writing to file.."

$PSSContent = @'
# Define your secret phrase
$secretPhrase = "<Enter our phase here>"

# Define a fixed IV for consistency
$fixedIV = "1234567890123456"
 
# Function to decrypt a password
function Decrypt-Password {
    param (
        [string]$encryptedPassword
    )

    # Convert secret phrase to bytes and truncate or expand to match the required key size
    $key = [System.Text.Encoding]::UTF8.GetBytes($secretPhrase)
    $key = $key[0..31] * (($key.Length / 32) + 1)  # Repeat key to match or exceed 256 bits (32 bytes)
    $key = $key[0..31]  # Take the first 32 bytes to ensure 256-bit key size

    # Convert encrypted password from base64 string to bytes
    $encryptedData = [Convert]::FromBase64String($encryptedPassword)

    # Create AES encryption object
    $aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $aes.KeySize = 256
    $aes.Key = $key
    $aes.IV = [System.Text.Encoding]::UTF8.GetBytes($fixedIV)  # Use fixed IV for consistency

    # Create decryptor
    $decryptor = $aes.CreateDecryptor()

    # Perform decryption
    $decryptedData = $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)

    # Convert decrypted data to plain text
    $plainTextPassword = [System.Text.Encoding]::UTF8.GetString($decryptedData)
    return $plainTextPassword
}


$EncryptedData = Get-Content -Path 'C:\Windows\Temp\<File Name>'
# Decrypt the password
$decryptedPassword = Decrypt-Password -encryptedPassword $EncryptedData
#Write-Host "Decrypted Password: $decryptedPassword"

$UserAccount = Get-LocalUser -Name "<Local user name>"
$Password = ConvertTo-SecureString $decryptedPassword -AsPlainText -Force
$UserAccount | Set-LocalUser -Password $Password
'@

$PSSContent | Out-File -FilePath $PackagerScript -Encoding utf8

$VBSContent = @'
Dim oShell, appcmd, strpath
Set oShell = CreateObject("WScript.Shell")
strpath=Replace(WScript.ScriptFullName,WScript.ScriptName,"")
appcmd = "Powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File " &chr(34)& strpath &"packager.ps1" &chr(34)
oShell.Run appcmd, 0, True
'@

$bytes = [System.Text.Encoding]::UTF8.GetBytes($VBSContent)
[System.IO.File]::WriteAllBytes($RunmeVBS, $bytes)

$jobname = 'Application packaging Test Script'
$Action = New-ScheduledTaskAction -Execute 'C:\Windows\system32\wscript.exe' -Argument '$($RunmeVBS)'
$Trigger1 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes "10")
$Trigger2 = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries #-Hidden -Compatibility "Win8"
Register-ScheduledTask -TaskName $jobname -Action $action -Trigger $trigger1,$Trigger2 -RunLevel Highest -User "NT AUTHORITY\SYSTEM" -Settings $settings -Force
<#
Unregister-ScheduledTask -TaskName 'Application packaging Test Script' -Confirm:$false
$PSFolder = "<Folder location>\Packager"
if(Test-Path $PSFolder){
Remove-Item -Path $PSFolder -Recurse -Force
}
#>

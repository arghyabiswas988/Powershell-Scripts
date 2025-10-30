# Construct the credentials object
$username = "punisher"

$password = Read-Host -Prompt "Pleease enter password for $username" -AsSecureString #Get-Credential -UserName $username -Message "Please enter password for $username" #ConvertTo-SecureString "test" -AsPlainText -Force    
$cred = New-Object PSCredential -Args $username, $password
#$cred = Get-Credential -UserName "$username" -Message "Enter password for $username"

Start-Process powershell.exe -Credential $cred -WorkingDirectory C:\ -WindowStyle Hidden `
 '-noprofile -command "Start-Process cmd.exe -Verb RunAs"'
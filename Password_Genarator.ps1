#$PW = Read-Host -Prompt "Enter your password" -AsSecureString
#Write-Host $PW
#$mypassword = $pw | ConvertFrom-SecureString
#Write-Host $mypassword
$PW = 'enter your password' #| ConvertTo-SecureString | Export-Clixml -Path "C:\Windows\8956235.xml"

$securePW = ConvertTo-SecureString -String $PW -AsPlainText -Force
$encryptedPW = ConvertFrom-SecureString -SecureString $securePW
$encryptedPW | Out-File -FilePath "C:\Windows\8956235.xml" -Force

# Retrieve encrypted password from file
$encryptedPW = Get-Content -Path "C:\Windows\8956235.xml"

# Convert encrypted password back to secure string
$securePW = ConvertTo-SecureString -String $encryptedPW


# Convert secure string to plain text for use in authentication (Not recommended to store plain text password)
$PlainPW = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePW))

Write-Host $PlainPW

#$XML = Get-Content -Path "C:\Windows\8956235.xml"
#$plaintextpassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($XML))
#Write-Host $plaintextpassword

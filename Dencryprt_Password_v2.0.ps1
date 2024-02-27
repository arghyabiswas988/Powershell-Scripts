# Define your secret phrase
$secretPhrase = "YourSecretPhraseHere"

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


$EncryptedData = Get-Content -Path "C:\Windows\Temp\874587458.tmp"
# Decrypt the password
$decryptedPassword = Decrypt-Password -encryptedPassword $EncryptedData
Write-Host "Decrypted Password: $decryptedPassword"

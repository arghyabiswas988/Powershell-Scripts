# Define your secret phrase
$secretPhrase = "YourSecretPhraseHere"

# Define a fixed IV for consistency
$fixedIV = "1234567890123456"

# Function to encrypt a password
function Encrypt-Password {
    param (
        [string]$password
    )

    # Convert secret phrase to bytes and truncate or expand to match the required key size
    $key = [System.Text.Encoding]::UTF8.GetBytes($secretPhrase)
    $key = $key[0..31] * (($key.Length / 32) + 1)  # Repeat key to match or exceed 256 bits (32 bytes)
    $key = $key[0..31]  # Take the first 32 bytes to ensure 256-bit key size

    # Convert password to bytes
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($password)

    # Create AES encryption object
    $aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $aes.KeySize = 256
    $aes.Key = $key
    $aes.IV = [System.Text.Encoding]::UTF8.GetBytes($fixedIV)  # Use fixed IV for consistency

    # Create encryptor
    $encryptor = $aes.CreateEncryptor()

    # Perform encryption
    $encryptedData = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length)

    # Convert encrypted data to base64 string
    $encryptedPassword = [Convert]::ToBase64String($encryptedData)
    return $encryptedPassword
}


# Example usage
$plainPassword = 'Fucking@P@ssw0rd#Crezy!Bitch'

# Encrypt the password
$encryptedPassword = Encrypt-Password -password $plainPassword
Write-Host "Encrypted Password: $encryptedPassword"
$encryptedPassword | Out-File -FilePath "C:\Windows\Temp\874587458.tmp" -Force

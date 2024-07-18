#cls
#
#
#
#
$TempFolder = "C:\Windows\Temp"
$TempFile = Join-Path $TempFolder "1098765435.tmp"

IF(Test-Path $TempFile){
    ################################## Dycryption start ##########################################################
    Write-Host "Temp file exists."
    $secretPhrase = "<Your secrate phase>"

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


$EncryptedData = Get-Content -Path "$($TempFile)"
# Decrypt the password
$decryptedPassword = Decrypt-Password -encryptedPassword $EncryptedData

    ###################################### Dycryption end ######################################################
    # Rest of your script...
    function Enable-Microphone {
        # Command to enable the microphone in BIOS
        # Modify this section to match your specific BIOS settings
        # You may need to adjust the BIOS setting name and value
        $biosSettingName = "MicrophoneAccess"
        $biosSettingValue = "Enable"
 
        # Execute the command to modify the BIOS setting
        # Replace this line with the appropriate command for your system
        # For example, if your BIOS supports PowerShell commands directly:
        # Set-BiosSetting -Name $biosSettingName -Value $biosSettingValue -Password $plainTextPassword
        #(gwmi -class Lenovo_GetBiosSelections -namespace root\wmi).GetBiosSelections("MicrophoneAccess") | Format-List Selections
        $SetSetting = ((gwmi -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("$biosSettingName,$biosSettingValue,$decryptedPassword,ascii,us")).Return
        $SaveSettings = ((gwmi -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings("$decryptedPassword,ascii,us”)).return
 
        # Display a message indicating success
        IF(($SetSetting -eq 'Success') -and ($SaveSettings -eq 'Success')){
            Write-Host "Microphone enabled successfully."
            Remove-Item -Path "$TempFile" -Force
            }
 
        # You may need to reboot your device for changes to take effect
    }
    # Main script logic
    Enable-Microphone
}

<#
$folderPath = "C:\Temp\O365_Setup"

Write-Host "Create a temporary zip file of the folder."
$zipPath = [System.IO.Path]::GetTempFileName() + ".zip"

Compress-Archive -Path $folderPath -DestinationPath $zipPath

Write-Host "Read the contents of the zip file as bytes."
$fileContent = Get-Content -Path $zipPath -Encoding Byte

Write-Host "Convert the file content to a base64-encoded string."
$base64String = [System.Convert]::ToBase64String($fileContent)

# Output the base64 string
#$base64String

Write-Host "Output the base64 string."
$outputFilePath = "C:\Temp\O365_Setup.txt"
Write-Host "Save the base64 string to a text file."
$base64String | Set-Content -Path $outputFilePath -Encoding ASCII

Write-Host "Clean up the temporary zip file."
Remove-Item -Path $zipPath
#>


#Content folder name is "O365_Setup".
$base64String = ''

$outputFolderPath = "C:\Temp"

Write-Host "Convert the base64 string to bytes."
$fileContent = [System.Convert]::FromBase64String($base64String)

Write-Host "Create a temporary zip file path."
$zipPath = [System.IO.Path]::GetTempFileName() + ".zip"

try {
    Write-Host "Save the base64 bytes to a temporary zip file."
    Set-Content -Path $zipPath -Value $fileContent -Encoding Byte

    Write-Host "Extract the contents of the zip file to the output folder."
    Expand-Archive -Path $zipPath -DestinationPath $outputFolderPath
}
finally {
    Write-Host "Clean up the temporary zip file."
    Remove-Item -Path $zipPath
}

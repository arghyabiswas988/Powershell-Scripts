<#
.SYNOPSIS
Search in soure folder and creating new folder in destinatination by replaching pattarn.

.DESCRIPTION
Search in soure folder and creating new folder in destinatination by replaching pattarn.

.EXAMPLE
Run the script. Change the variables and define patterns.

.COPYRIGHT
Arghya Biswas. Email:arghyabiswas988@gmail.com
#>
$Source = "C:\Temp\Source_Video"
$Destination = "C:\Temp\Converted_Videos"
$pattern1 = '1080'
$pattern2 = '720'

$FolderList = Get-ChildItem -Path "$Source" -Exclude "*.*" | select Name

#Write-Host $FolderList.name

foreach($Folder in $FolderList){

$FolderName = $Folder.Name

#Write-Host $FolderName

$new_name = $FolderName -replace $pattern1, $pattern2

#Write-Host $new_name

New-Item -Path (Join-Path $Destination $new_name) -ItemType Directory -Force

}
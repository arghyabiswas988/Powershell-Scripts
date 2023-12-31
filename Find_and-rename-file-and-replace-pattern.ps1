<#
.SYNOPSIS
Search in soure folder and renaming files with pattarn.

.DESCRIPTION
Search in soure folder and renaming files with pattarn.

.EXAMPLE
Run the script. Change the variables and define patterns.

.COPYRIGHT
Arghya Biswas. Email:arghyabiswas988@gmail.com
#>
$Source = "F:\IDM\Video"
#$Destination = "C:\Temp\Converted_Videos"
$pattern1 = 'Volledige'
$pattern2 = 'Full'

$List = Get-ChildItem | select name

#Write-Host $FolderList.name

foreach($File in $List){

$FileName = $File.Name

#Write-Host $FileName

$new_name = $FileName -replace $pattern1, $pattern2

#Write-Host $new_name

#Write-Host (Join-Path "$Source" "$FileName")

Rename-Item -Path (Join-Path "$Source" "$FileName") -NewName "$new_name" -Force

}

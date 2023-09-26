<#
$Target = "\\DESKTOP-MSI\Storage1_4TB\Dispute.jpg"
$Link = "C:\Temp\Dispute.jpg"
New-Item -ItemType SymbolicLink -Path "$Link" -Target "$Target"

#New-Item -Path "C:\Temp" -ItemType File -Name "test.mp4" -Force
#>
$Folder = "C:\Temp\Downloads\IDM\Video"

$DesktopIni = @"
[.ShellClassInfo]
IconResource=C:\WINDOWS\System32\SHELL32.dll,115
"@

$TargetDirectory = $Folder
#Test-Path (Join-Path "$TargetDirectory" "desktop.ini")

#Remove-Item -Path "$($TargetDirectory)\desktop.ini" -Force
#Create/Add content to the desktop.ini file
Add-Content "$($TargetDirectory)\desktop.ini" -Value $DesktopIni -Force

#Set the attributes for $DesktopIni
(Get-Item "$($TargetDirectory)\desktop.ini" -Force).Attributes = 'Hidden, System, Archive'

#Finally, set the folder's attributes
(Get-Item $TargetDirectory -Force).Attributes = 'ReadOnly, Directory'
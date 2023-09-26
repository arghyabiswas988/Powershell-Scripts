<#
$Target = "\\DESKTOP-MSI\Storage1_4TB\Dispute.jpg"
$Link = "C:\Temp\Dispute.jpg"
New-Item -ItemType SymbolicLink -Path "$Link" -Target "$Target"

#New-Item -Path "C:\Temp" -ItemType File -Name "test.mp4" -Force
#>
$Folder = "D:\Downloads\IDM\Video"
$Target = "\\DESKTOP-MSI\Storage3_4TB\IDM\Video"
$TargetDirectory = $Folder

IF(!(Test-Path $Folder)){
New-Item -Path "$Folder" -ItemType Directory -Force
}

New-Item -ItemType SymbolicLink -Path "$Folder" -Target "$Target" -Force

$DesktopINI = (Join-Path "$TargetDirectory" "desktop.ini")

IF(Test-Path $DesktopINI){
Remove-Item -Path "$($TargetDirectory)\desktop.ini" -Force
}

IF(!(Test-Path $DesktopINI)){

$DesktopIni = @"
[.ShellClassInfo]
IconResource=C:\WINDOWS\System32\SHELL32.dll,115
"@


#Test-Path (Join-Path "$TargetDirectory" "desktop.ini")

#Remove-Item -Path "$($TargetDirectory)\desktop.ini" -Force
#Create/Add content to the desktop.ini file
Add-Content "$($TargetDirectory)\desktop.ini" -Value $DesktopIni -Force

#Set the attributes for $DesktopIni
(Get-Item "$($TargetDirectory)\desktop.ini" -Force).Attributes = 'Hidden, System, Archive'

#Finally, set the folder's attributes
(Get-Item $TargetDirectory -Force).Attributes = 'ReadOnly, Directory'
}

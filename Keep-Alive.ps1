<#
.SYNOPSIS
Keep system awake. by pressing SCROLLLOCK.

.DESCRIPTION
Keep system awake. by pressing SCROLLLOCK.

.EXAMPLE
Run the script. Change the variables and define patterns.

.COPYRIGHT
Arghya Biswas. Email:arghyabiswas988@gmail.com
#>

$Folder = "C:\Temp\Keep-Alive"
If (!(Test-Path $Folder)) {
    Write-Host "Creating Temp folder."
    New-Item -Path $Folder -ItemType Directory
}

$DesktopIni = @"
[.ShellClassInfo]
IconResource=C:\WINDOWS\System32\SHELL32.dll,41
"@

$TargetDirectory = $Folder
#Test-Path (Join-Path "$TargetDirectory" "desktop.ini")

#Create/Add content to the desktop.ini file
Add-Content "$($TargetDirectory)\desktop.ini" -Value $DesktopIni

#Set the attributes for $DesktopIni
(Get-Item "$($TargetDirectory)\desktop.ini" -Force).Attributes = 'Hidden, System, Archive'

#Finally, set the folder's attributes
(Get-Item $TargetDirectory -Force).Attributes = 'ReadOnly, Directory'

# get attributes.
#(Get-Item "$Folder").attributes

Write-Host "Writing keep-alive scripts..."
# Define the file path and name
$PSScript = (Join-Path "$Folder" "Keep-Alive.ps1")

Write-Host "Creating new PS Script..."
New-Item -Path $PSScript -ItemType File -Force

Write-Host "Writing content to PS Script..."

$PSScriptContent = @'
$wsh = New-Object -ComObject WScript.Shell
while (1) {
  $wsh.SendKeys('+{SCROLLLOCK}')
  Start-Sleep -seconds 59
}
'@

Write-Host "Writing to the PS Script..."
$PSScriptContent | Out-File -FilePath $PSScript -Encoding UTF8 -Force


$SourceFilePath = "Powershell.exe"
$ShortcutPath = (Join-Path "$env:USERPROFILE" "Desktop\Keep-Alive.lnk")
$WScriptObj = New-Object -ComObject ("WScript.Shell")
$shortcut = $WscriptObj.CreateShortcut($ShortcutPath)
$shortcut.TargetPath = "$SourceFilePath"
$shortcut.WorkingDirectory = "$env:USERPROFILE"
$shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""$PSScript"""
$shortcut.WindowStyle = 7 #3=Maximized 7=Minimized 4=Normal
#$ShortCut.Hotkey = "CTRL+SHIFT+T"
$shortcut.Description = 'Keep active your system.'
$shortcut.IconLocation = "shell32.dll,41"
$shortcut.Save()

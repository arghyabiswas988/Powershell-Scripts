﻿$UserTemp = Join-Path $Env:TEMP "\*"
$WindowsTemp = Join-Path $env:windir "Temp\*"

Remove-Item -Path $UserTemp -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $WindowsTemp -Recurse -Force -ErrorAction SilentlyContinue

$WinUpdate = Get-Service -Name wuauserv
if ($WinUpdate.Status -ne "Stopped"){
Stop-Service -Name wuauserv -Force
}

$SoftwarePath = Join-Path $env:windir "SoftwareDistribution\*"

Remove-Item -Path $SoftwarePath -Recurse -Force -ErrorAction SilentlyContinue

#To configure.
#cleanmgr /sageset:1

#Clean by selecting.
#cleanmgr /d C

cleanmgr /sagerun:1 | out-Null
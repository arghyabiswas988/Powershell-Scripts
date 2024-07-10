

$InstallDir = Join-Path $env:ProgramData "Microsoft\Store"
if (!(Test-Path -Path $InstallDir)){
    New-Item -Path "$InstallDir" -Type Directory -Force
    }

$PSScript = "$InstallDir\MSStore_App_Force_Update.ps1"

New-Item -Path "$PSScript" -ItemType File -Force

$PSScriptContent = @'
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()
'@

$PSScriptContent | Out-File -FilePath $PSScript -Encoding utf8 -Force
$jobname = 'Microsoft Store app force update'
$cmdArgs = '/c start /min "" powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $PSScript + '"'
$Action = New-ScheduledTaskAction -Execute 'CMD.exe' -Argument $cmdArgs
$Trigger1 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes "240")
$Trigger2 = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries #-Hidden -Compatibility "Win8"
Register-ScheduledTask -TaskName $jobname -Action $action -Trigger $Trigger2,$Trigger1 -RunLevel Highest -User "NT AUTHORITY\SYSTEM" -Settings $settings -Force
<#
Unregister-ScheduledTask -TaskName 'Microsoft Store app force update' -Confirm:$false
$InstallDir = Join-Path $env:ProgramData "Microsoft\Store"
if(Test-Path $InstallDir){
Remove-Item -Path $InstallDir -Recurse -Force
}
#>
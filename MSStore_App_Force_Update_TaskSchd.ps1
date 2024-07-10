

$InstallDir = Join-Path $env:ProgramData "Microsoft\Store"
if (!(Test-Path -Path $InstallDir)){
    New-Item -Path "$InstallDir" -Type Directory -Force | Out-Null
    }

$PSScript = "$InstallDir\MSStore_App_Force_Update.ps1"

New-Item -Path "$PSScript" -ItemType File -Force

$PSScriptContent = @'
<# #===============================================
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()
#> #===============================================

$ServiceList = @(
    'InstallService'
    'BITS'
    'wuauserv'
    'StorSvc'
    'AppXSvc'
    )

foreach($Service in $ServiceList){
    $ServiceStatus = Get-Service -Name $Service
    if($ServiceStatus.Status -ne 'Running'){
        Write-Host "$Service is not running." -ForegroundColor Red
        Write-Host "Attempting to start $Service" -ForegroundColor Yellow
        $Result = Start-Service -Name $Service -PassThru -Confirm:$false
        if ($Result.Status -eq 'Running'){
            Write-Host "$Service started successfully" -ForegroundColor Green
            }
        }
    }


$Update = Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName "UpdateScanMethod"
EXIT $Update.ReturnValue
'@

$PSScriptContent | Out-File -FilePath $PSScript -Encoding utf8 -Force | Out-Null
$jobname = 'Microsoft Store app force update'
$JobDescription = 'Keeps your Microsoft store apps up to date.'
$cmdArgs = '/c start /min /wait "Updating.." powershell -WindowStyle Hidden -Ex Bypass -File "' + $PSScript + '"'
$Action = New-ScheduledTaskAction -Execute 'CMD.exe' -Argument $cmdArgs
$Trigger1 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes "240")
$Trigger2 = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries #-Hidden -Compatibility "Win8"
Register-ScheduledTask -TaskName $jobname -Description $JobDescription -Action $action -Trigger $Trigger2,$Trigger1 -RunLevel Highest -User "NT AUTHORITY\SYSTEM" -Settings $settings -Force | Out-Null
<#
Unregister-ScheduledTask -TaskName 'Microsoft Store app force update' -Confirm:$false
$InstallDir = Join-Path $env:ProgramData "Microsoft\Store"
if(Test-Path $InstallDir){
Remove-Item -Path $InstallDir -Recurse -Force
}
#>

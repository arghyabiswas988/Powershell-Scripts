# Detection Script v1.8.
#This script checks if the microphone is enabled in the BIOS and Microphoneexits with code 1 if remediation is needed (microphone is disabled), or exits with code 0 if no remediation is needed (microphone is enabled).
# Detection Script: Check if the microphone is enabled in BIOS.
#CLS

$dInfo = Get-ComputerInfo
$dFamily = "$($dInfo.CsSystemFamily)"
$dSerial = "$($dInfo.BiosSeralNumber)"
$dType = "$($dInfo.CsPCSystemType)"
$dModel = "$($dInfo.CsModel)"
 
if ($dFamily -match "ThinkPad"){
    Write-Host "$dFamily,$dModel,$dSerial,$dType."
    }
if ($dFamily -match "ThinkCentre"){
    Write-Host "$dFamily,$dModel,$dSerial,$dType."
    EXIT 0
    }


$Processor = Get-CimInstance -Class CIM_Processor -ErrorAction Stop
if ($Processor.Manufacturer -eq 'AuthenticAMD'){
    Write-Host "AMD Processor" -ForegroundColor Red
    }
if ($Processor.Manufacturer -eq 'GenuineIntel'){
    Write-Host "Intel Processor" -ForegroundColor Green
    EXIT 0
    }

function Check-MicrophoneStatus {
    # Command to check the status of the microphone in BIOS
    $micStatus = (Get-WmiObject -Namespace "root\wmi" -Class "Lenovo_BiosSetting").Where({$_.CurrentSetting -like "*Microphone*"})
 
    if ($micStatus.CurrentSetting -eq "MicrophoneAccess,Disable") {
        return $false
    } else {
        return $true
    }
}
 
# Main script logic
$microphoneEnabled = Check-MicrophoneStatus

$bMIC = (Get-WmiObject -Namespace "root\wmi" -Class "Lenovo_BiosSetting").Where({$_.CurrentSetting -like "*Microphone*"})
$BIOSMICStatus = "$($bMIC.CurrentSetting)"
#$BIOSMICStatus

if (-not $microphoneEnabled) {
    # Exit code indicating remediation is needed
    Write-Host "Mic disabled,$($micStatus.CurrentSetting)" -ForegroundColor Red

    $TempFolder = "C:\Windows\Temp"
    $TempFile = Join-Path $TempFolder "1098765435.tmp"

    New-Item -Path "$TempFile" -ItemType File -Force | Out-Null

$TempFileContent = @'
<encrypted text here>
'@
    $TempFileContent | Out-File -FilePath $TempFile -Encoding utf8

    }

$MIC = Get-PnpDevice | Where-Object FriendlyName -like '*Microphone Array*' -ErrorAction SilentlyContinue
if (($MIC.Status -eq 'OK') -and ($MIC.Present -eq 'True') -and ($microphoneEnabled -eq $true)){
    Write-Host "$($MIC.FriendlyName) present and $BIOSMICStatus" -ForegroundColor Green
    EXIT 0
    }
else {
    Write-Host "Internal Mic not found,$BIOSMICStatus" -ForegroundColor Red
    EXIT 1
    }

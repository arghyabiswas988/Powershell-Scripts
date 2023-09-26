$Devicelist = import-csv -Path "C:\Temp\SCCM_PS_Script\Intune__2023-08-30T10_02_06.680Z.csv" | select Device

#$Device = $Devicelist.Device

#Write-Host $Devicelist

foreach($Device in $Devicelist){
$DeviceName = $Device.Device
Get-CMUserDeviceAffinity -DeviceName "$DeviceName" | Select ResourceName,UniqueUserName | Export-Csv -NoTypeInformation -Append -Path "C:\Temp\SCCM_PS_Script\Primary_user.csv"

}

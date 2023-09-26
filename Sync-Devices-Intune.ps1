#Get-IntuneManagedDevice -Filter "contains(deviceName,'MMD-20524938970')" | Invoke-IntuneManagedDeviceSyncDevice

$device_List = Import-CSV -Path "C:\Temp\Sync_Machines.csv"

foreach ($device in $device_List) {
#Write-Host Initiating sync on $device
$Name = $device.device
Get-IntuneManagedDevice -Filter "contains(deviceName,'$Name')" | Invoke-IntuneManagedDeviceSyncDevice
#Invoke-IntuneManagedDeviceSyncDevice -managedDeviceId $Machine.managedDeviceId
Write-Host "Sending Sync request to Device with DeviceID '$Name'" -ForegroundColor Yellow
}

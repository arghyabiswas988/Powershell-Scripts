$device_List = Import-CSV -Path "C:\Temp\Reboot\REBOOT_Machine.csv"
foreach ($device in $device_List) {
#Write-Host Initiating sync on $device
$Name = $device.device
Get-IntuneManagedDevice -Filter "contains(deviceName,'$Name')" | Invoke-DeviceManagement_ManagedDevices_RebootNow
#Invoke-IntuneManagedDeviceSyncDevice -managedDeviceId $Machine.managedDeviceId
Write-Host "Sending Restart request to Device '$Name'" -ForegroundColor Yellow
}

$Machine_List = Import-Csv -Path "C:\Temp\HHU\HHU_List.csv"
foreach($Name in $Machine_List){

#Write-Host $Name.Name
$Machine_Name = $Name.name
#$ObjectID = (Get-AzureADDevice -SearchString "$Machine_Name" | select ObjectId).ObjectId | export-csv "C:\Temp\HHU\HHU_ObjectID_List.csv" -Append -NoTypeInformation
#$ObjectID | export-csv "C:\Temp\HHU\HHU_ObjectID_List.csv" -Append -NoTypeInformation
#Write-Host $ObjectID
Get-AzureADDevice -Filter "DisplayName eq '$Machine_Name'" | Select-Object Displayname, ObjectId | Export-Csv "C:\Temp\HHU\HHU_ObjectID_List.csv" -Append -NoTypeInformation
#Write-host "Object Id for device $Machine_Name is $ObjectID"
}
<#
$devices = Import-Csv -Path "C:\Temp\HHU\HHU_List.csv"  
$devices | ForEach {Get-AzureADDevice -Filter "DisplayName eq '$_'"} | Select-Object Displayname, ObjectId | Export-Csv "C:\Temp\HHU\HHU_ObjectID_List.csv" -Append -NoTypeInformation
#>

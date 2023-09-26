$Machine_List = Import-Csv -Path "C:\Temp\HHU\HHU_List.csv"
$AD_Group = "<Group Name>"
#$AD_Group = "Cus_MSDE_Win10_Computers"
#$AD_Group =  "Windows10 Defender Migrated_Devices"

foreach($Name in $Machine_List){

#Write-Host $Name.Name
$Machine_Name = $Name.name
#((Get-ADComputer "$Machine_Name" -properties memberof).MemberOf | get-adgroup).name
Write-Host "Adding $Machine_Name to AD Group $AD_Group"
ADD-ADGroupMember "$AD_Group" -members "$Machine_Name$"
}

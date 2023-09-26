
$Email_List = Import-Csv -Path "C:\Temp\HHU\HHU_User_List.csv"
foreach($Email in $Email_List){

#Write-Host $Name.Name
#$Name = $User.UserId
#Write-Host $Name
#$Display_Name = Get-AzureADUser -SearchString "$Name" | Select DisplayName

$User_Email = $Email.Email
Write-host $User_Email
Get-AzureADUser -Filter "UserPrincipalName eq '$User_Email'" | Select-Object MailNickName,Displayname, ObjectId | Export-Csv "C:\Temp\HHU\HHU_ObjectID_User_List.csv" -Append -NoTypeInformation
#Get-AzureADUser -Filter "MailNickName eq 'ryan09s'" | Select-Object Displayname, ObjectId
}
<#
$devices = Import-Csv -Path "C:\Temp\HHU\HHU_List.csv"  
$devices | ForEach {Get-AzureADDevice -Filter "DisplayName eq '$_'"} | Select-Object Displayname, ObjectId | Export-Csv "C:\Temp\HHU\HHU_ObjectID_List.csv" -Append -NoTypeInformation
#>

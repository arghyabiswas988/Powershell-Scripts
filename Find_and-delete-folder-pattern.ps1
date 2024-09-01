$Source = "G:\Hot"
$pattern1 = '540'
#Set-Location $Source
cls
#$FolderList = Get-ChildItem -Path "$Source" -Exclude "*.*" -Recurse | Where-Object Name -like "*540*"
$FolderList = Get-ChildItem "$Source" -recurse | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -match "$pattern1"} | Remove-Item -Recurse -Force

<#
Foreach ($Folder in $FolderList){
    $FolderName = $Folder.Name
    $FolderPath = $Folder.FullName
    #Write-Host "$FolderName"
    Write-Host "$FolderPath"
    #$RemoveFolder = Join-Path $Source $FolderName
    #Write-Host $RemoveFolder
    Remove-Item -Path "$FolderPath" -Recurse -Force
    }
#>

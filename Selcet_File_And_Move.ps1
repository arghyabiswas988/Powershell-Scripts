$Files = Get-ChildItem -Path "<Folder to check>" -Recurse -Include *.mp4 -File -Exclude -Directory #| select Fullname
Foreach($File in $Files){
$FileName = $File.Name
Write-Host "Moving file $($File.Name)."
#Write-Host $File.FullName
Move-Item -Path $($File.FullName) -Destination "<Folder to move>" -Force
}

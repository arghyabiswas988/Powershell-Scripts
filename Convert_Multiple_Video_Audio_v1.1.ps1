cls
$mPath = "<Source path>"
$ffmpeg = "<path of ffmpeg.exe>"
$fList = Get-ChildItem -Path "$mPath" -Recurse -Include *.mp4 | Where-Object {$_.PSIsContainer -eq $false}
foreach ($File in $fList){
    $nFile = [io.path]::ChangeExtension($File.FullName, '.mp3')
    #Write-Host "$File"
    Write-Host "Converting $File to $nFile"
    #Start-Process $ffmpeg -ArgumentList "-i $($File) -b:a 128K -vn $($nFile)" -Wait #-NoNewWindow
    Start-Process $ffmpeg -ArgumentList "-i ""$File"" -b:a 128K -vn ""$nFile""" -Wait
    }

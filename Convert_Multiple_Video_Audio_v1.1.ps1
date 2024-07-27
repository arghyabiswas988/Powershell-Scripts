cls
$mPath = "D:\Downloads\IDM\Music"
$ffmpeg = "C:\Temp\MPV_Player\ffmpeg.exe"
$fList = Get-ChildItem -Path "$mPath" -Recurse -Include *.mp4 | Where-Object {$_.PSIsContainer -eq $false}
foreach ($File in $fList){
    $nFile = [io.path]::ChangeExtension($File.FullName, '.mp3')
    #Write-Host "$File"
    Write-Host "Converting $File to $nFile"
    #Start-Process $ffmpeg -ArgumentList "-i $($File) -b:a 128K -vn $($nFile)" -Wait #-NoNewWindow
    Start-Process $ffmpeg -ArgumentList "-i ""$File"" -b:a 128K -vn ""$nFile""" -Wait
    }
<#
$File = "D:\Downloads\IDM\Music\অন্ধকারের উৎস হতে!! (ভয়ের গল্প ) - @mhstation _ Sayak Aman _ Oeeshik Majumdar _ Bhuter Golpo.mp4"
$nFile = "D:\Downloads\IDM\Music\অন্ধকারের উৎস হতে!! (ভয়ের গল্প ) - @mhstation _ Sayak Aman _ Oeeshik Majumdar _ Bhuter Golpo.mp3"
Start-Process $ffmpeg -ArgumentList "-i ""$File"" -b:a 192K -vn ""$nFile""" -Wait
#>

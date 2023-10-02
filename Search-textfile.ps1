$Content = Get-Content "C:\Temp\Downloads\smalldict.txt"

#$Content | Measure-Object -Line #-Word -Character 

foreach($line in $Content){
#Write-Host $line
$Char = "$line" | Measure -Character #| select Characters
#Write-Host $Char.Characters
$CharCount = $Char.Characters
if (($CharCount -ge 8) -AND ($CharCount -le 16)){
    #Write-Host $line
    $line | Out-File -FilePath "C:\Temp\Downloads\smalldict-8-16.txt" -Append -Encoding utf8
    }
}

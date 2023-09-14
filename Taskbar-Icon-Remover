$logpath = "C:\Temp\Logs"

If (!(test-path $logpath)){
New-Item -Path $logpath -ItemType Directory -Force
}

$logfile = 'TaskBar-Icon-Remover-' + (Get-Date -Format 'hh-mm-ss-MM-yyyy') + '.log'

Start-Transcript -Path "$logpath\$logfile" -IncludeInvocationHeader

Write-Host "Started logging"
<#
$ScriptFolder = "C:\Temp\IconRemover"
If(!(Test-Path $ScriptFolder)){
New-Item -Path $ScriptFolder -ItemType Directory -Force
}
#>

$base64String = 'UEsDBBQAAAAIADBKmFaqOebpmAAAALkAAAAhAAAASWNvblJlbW92ZXJcSWNvblJlbW92YWxfUnVuTWUudmJzLY6xCsIwFEX3Qv7h8SYFW3QVnCqCk2ILLgVJ40OjSV5IUrV/b7VdLhfOcM5WW4h3Mmah2FrpriKbDmwAPb8p/HFBH4J8GNUlze7IRqse2t7LGCF3bPjGkO+0IUAs101N1je1jM9WhstesQtk+UWh8HGFiCKrKI3iwVMGkokO7YNUmuG5UkH7VFQ/inORjQGnzsGUtliK7AtQSwMEFAAAAAgAAHMuVzuxNi2eAQAA8wgAACMAAABJY29uUmVtb3ZlclxUYXNrYmFyX0ljb25yZW1vdmVyLnBzMeVVW2/TMBR+j5T/cNSWJZFItC0pW8udtkOVxmDrBi+WJsc5bU0T29guq1Ty33ErdQLCMzzk2efyXY7PedHtUaUErRBeQueL1EXH98LwCh/ij/lXZBbikaxgtsSyTN4qVXJGLZciSq5czkxRhmFgdq/D4XCbnaZZkQ3y+Pg068dZMU/j/Oz8OE7PB+kgS7P+MzypgyiZWqxMGMEPeL3t3e9LQYzf4ICljpLPqPM/QhKNqtw3PAqeBkEEcUUtW0JwJxQXMNcOqKVmlVMd1C7xyS5xLKc2jJ5DDzfIHMee1Wusfe9X2pMNw7KFvD9wpqWRcwuTYoEtFOCClwiTjSqlRt1C/u+lXDgFRktXoY3+T4VFLdC2eQZmgis4ArNCV64l/LvjySV0RkNyZ1AbYr6X9zk3Dyd9ShzNMbWU3EhacbEgjzuSNIaFXK85W8ElXQu23JeCT1wILMitA/KOavLbfklKsXL6dl/5nnNgL6exDtSb0PcOl/fxFDV3c2NZ/XV6G3Y2/njkexcumDrtwh0KcOod0ETb/+m/6/APvK9/AlBLAQIUABQAAAAIADBKmFaqOebpmAAAALkAAAAhAAAAAAAAAAAAAAAAAAAAAABJY29uUmVtb3ZlclxJY29uUmVtb3ZhbF9SdW5NZS52YnNQSwECFAAUAAAACAAAcy5XO7E2LZ4BAADzCAAAIwAAAAAAAAAAAAAAAADXAAAASWNvblJlbW92ZXJcVGFza2Jhcl9JY29ucmVtb3Zlci5wczFQSwUGAAAAAAIAAgCgAAAAtgIAAAAA'

$outputFolderPath = "C:\Temp"

Write-Host "Convert the base64 string to bytes."
$fileContent = [System.Convert]::FromBase64String($base64String)

Write-Host "Create a temporary zip file path."
$zipPath = [System.IO.Path]::GetTempFileName() + ".zip"

try {
    Write-Host "Save the base64 bytes to a temporary zip file."
    Set-Content -Path $zipPath -Value $fileContent -Encoding Byte -Force

    Write-Host "Extract the contents of the zip file to the output folder."
    Expand-Archive -Path $zipPath -DestinationPath $outputFolderPath -Force
}
finally {
    Write-Host "Clean up the temporary zip file."
    Remove-Item -Path $zipPath
}

$ScriptFolder = "C:\Temp\IconRemover"

$VBScript = Join-Path $ScriptFolder "IconRemoval_RunMe.vbs"

$PSScript = Join-Path $ScriptFolder "Taskbar_Iconremover.ps1"


Write-Host "Creating Schdule Task..."
$Action = New-ScheduledTaskAction -Execute 'Wscript.exe' -Argument "$VBScript"
$Trigger = New-ScheduledTaskTrigger -AtLogOn #-RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Minutes 30)
$Trigger.Repetition = (New-ScheduledTaskTrigger -once -at "9am" -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Hours 24)).repetition
$Principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" #-RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$Task = New-ScheduledTask -Action $Action -Principal $Principal -Trigger $Trigger -Settings $Settings
Register-ScheduledTask "Taskbar Icon Remover" -InputObject $Task -Force

Stop-Transcript -Verbose

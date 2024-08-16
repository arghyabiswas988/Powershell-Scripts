function Get-OfficeInstallation {
    $officeFound = $false

    # Check Click-to-Run installations
    $clickToRunPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    if (Test-Path $clickToRunPath) {
        $officeVersion = Get-ItemProperty -Path $clickToRunPath -Name "VersionToReport" -ErrorAction SilentlyContinue
        $bitness = Get-ItemProperty -Path $clickToRunPath -Name "Platform" -ErrorAction SilentlyContinue

        if ($officeVersion) {
            Write-Output "Microsoft Outlook $($officeVersion.VersionToReport) is installed."
            Write-Output "Bitness: $($bitness.Platform)"
            $officeFound = $true
        }
    }

    # Fallback: Check for common Outlook executables
    if (-not $officeFound) {
        $outlookExecutables = @(
            "$env:ProgramFiles\Microsoft Office\root\Office16\OUTLOOK.EXE",
            "$env:ProgramFiles(x86)\Microsoft Office\root\Office16\OUTLOOK.EXE"
        )
        foreach ($exe in $outlookExecutables) {
            if (Test-Path $exe) {
                $officeFound = $true
                $bitness = if ($exe -like "*Program Files (x86)*") { "32-bit" } else { "64-bit" }
                Write-Output "Microsoft Outlook is installed. Bitness: $bitness"
                break
            }
        }
    }

    if (-not $officeFound) {
        Write-Output "Microsoft Outlook is not installed."
    }
}
cls
# Call the function
Get-OfficeInstallation

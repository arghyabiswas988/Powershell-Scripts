# Relaunch in 64-bit PowerShell if running 32-bit under InstallShield
if ($env:PROCESSOR_ARCHITECTURE -eq "x86" -and $env:PROCESSOR_ARCHITEW6432) {
    $scriptPath = $MyInvocation.MyCommand.Definition

    # Relaunch the script with 64-bit PowerShell
    & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "$scriptPath"

    # Exit 32-bit process after relaunch
    exit
}




try {
    # Detect the active session user (excluding SYSTEM)
    $LoggedOnUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName

    if ($LoggedOnUser -and $LoggedOnUser -ne "" -and $LoggedOnUser -ne "NT AUTHORITY\SYSTEM") {
        try {
            $Domain, $Username = $LoggedOnUser -split '\\'

            # Get user's SID
            $SID = (Get-WmiObject Win32_UserAccount | Where-Object {
                $_.Name -eq $Username -and $_.Domain -eq $Domain
            }).SID

            if ($SID) {
                try {
                    # Equivalent to HKCU for logged-on user
                    $RegPath = "Registry::HKEY_USERS\$SID\Software\Palo Alto Networks\GlobalProtect\PSMService"
                    $RegName = "previouscertificate"
                    $RegValue = "bnhaaavvftnnk= co, dc= local, asgtvbghjkimnbvggtrf_ghyhgghhh"

                    if (-not (Test-Path $RegPath)) {
                        Write-Output "Regisrty path doesn't exist, creating registry path,please wait..."
                        New-Item -Path $RegPath -Force | Out-Null
                    }

                    New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue -PropertyType String -Force -ErrorAction Stop | Out-Null

                    Write-Output "Registry value set for $LoggedOnUser ($SID)"
                } catch {
                    Write-Error "Failed to set registry key/value: $_"
                }
            } else {
                Write-Warning "SID resolution failed for $LoggedOnUser"
            }
        } catch {
            Write-Error "User SID lookup error: $_"
        }
    } else {
        Write-Warning "No valid non-SYSTEM user logged in. Action skipped."
    }
} catch {
    Write-Error "Fatal error occurred: $_"
}
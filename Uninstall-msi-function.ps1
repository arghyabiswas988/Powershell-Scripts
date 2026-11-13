function Uninstall-MsiApp {
    <#
    .SYNOPSIS
        Uninstalls an MSI application using its Product Code.
    
    .DESCRIPTION
        This function uses msiexec.exe to silently uninstall an MSI package. 
        It captures exit codes, generates an MSI log file, and logs script activities.
    
    .PARAMETER ProductCode
        The GUID of the MSI application (e.g., "{12345678-1234-1234-1234-123456789012}").
        
    .PARAMETER MsiLogPath
        Optional path for the verbose MSI log file. 
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProductCode,

        [Parameter(Mandatory=$false)]
        [string]$MsiLogPath = "C:\Temp\Uninstall_$($ProductCode -replace '[{}]','').log",
        
        [Parameter(Mandatory=$false)]
        [string]$ScriptLogPath = "C:\Temp\UninstallScript.log"
    )

    # Helper function for script logging
    function Write-Log {
        param([string]$Message, [string]$Level = "INFO")
        $logEntry = "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) [$Level] - $Message"
        Write-Host $logEntry
        Add-Content -Path $ScriptLogPath -Value $logEntry
    }

    # Ensure log directory exists
    $logDir = Split-Path $MsiLogPath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Write-Log "Starting uninstallation process for Product Code: $ProductCode"
    
    try {
        # /x = uninstall, /qn = quiet (no UI), /norestart = suppress reboot, /L*V = verbose logging
        $arguments = "/x $ProductCode /qn /norestart /L*V `"$MsiLogPath`""
        
        Write-Log "Executing command: msiexec.exe $arguments"
        
        # Start-Process with -Wait ensures the script pauses until the uninstaller finishes
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        
        $exitCode = $process.ExitCode
        
        # Evaluate standard msiexec exit codes
        switch ($exitCode) {
            0 { 
                Write-Log "Uninstallation completed successfully." 
            }
            1605 {
                Write-Log "Product code not found on this system. It may already be uninstalled." "WARNING"
            }
            { $_ -in 1641, 3010 } { 
                Write-Log "Uninstallation completed successfully, but a system reboot is required." "WARNING" 
            }
            1603 {
                Write-Log "Fatal error during uninstallation. Review the MSI log at $MsiLogPath" "ERROR"
                throw "Fatal error 1603."
            }
            default { 
                Write-Log "Uninstallation failed with exit code: $exitCode. Review the MSI log at $MsiLogPath" "ERROR"
                throw "Unexpected exit code: $exitCode"
            }
        }
    }
    catch {
        Write-Log "Exception occurred: $($_.Exception.Message)" "ERROR"
    }
    finally {
        Write-Log "Uninstallation script routine finished."
        Write-Log "---------------------------------------------------"
    }
}

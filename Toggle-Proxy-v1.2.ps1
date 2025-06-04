Add-Type -AssemblyName System.Windows.Forms

# Define registry path
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

# Define your proxy server here
$proxyAddress = "http://proxy.company.com:8080"

# Define local bypass value for ProxyOverride
$localBypass = "*.local.*"

# Define log file path
$logFile = "$env:USERPROFILE\proxy_toggle_log.txt"

# Ensure required registry values exist
if (-not (Get-ItemProperty -Path $regPath -Name AutoDetect -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $regPath -Name AutoDetect -PropertyType DWord -Value 1 | Out-Null
}
if (-not (Get-ItemProperty -Path $regPath -Name ProxyEnable -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $regPath -Name ProxyEnable -PropertyType DWord -Value 0 | Out-Null
}
if (-not (Get-ItemProperty -Path $regPath -Name ProxyOverride -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $regPath -Name ProxyOverride -PropertyType String -Value "" | Out-Null
}

# Read current settings
$settings = Get-ItemProperty -Path $regPath
$autoDetect = $settings.AutoDetect
$proxyEnable = $settings.ProxyEnable
$proxyOverride = $settings.ProxyOverride

# Toggle logic
if ($autoDetect -eq 1 -and $proxyEnable -eq 0) {
    # Switch to Proxy Server mode
    Set-ItemProperty -Path $regPath -Name AutoDetect -Value 0
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value $proxyAddress

    # Ensure $localBypass is in ProxyOverride
    if ([string]::IsNullOrWhiteSpace($proxyOverride)) {
        $newOverride = $localBypass
    } elseif ($proxyOverride -notlike "*$localBypass*") {
        $newOverride = "$proxyOverride;$localBypass"
    } else {
        $newOverride = $proxyOverride
    }
    Set-ItemProperty -Path $regPath -Name ProxyOverride -Value $newOverride

    $message = "Switched to Proxy Server mode.`nProxy: $proxyAddress."
}
else {
    # Switch to Automatically Detect Settings mode
    Set-ItemProperty -Path $regPath -Name AutoDetect -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0
    $message = "Switched to Automatically Detect Settings mode."
}

# Notify system of the change
rundll32.exe inetcpl.cpl,ClearMyTracksByProcess 8

# Force WinINet to apply new settings
$winInet = @"
using System;
using System.Runtime.InteropServices;
public class RefreshIESettings {
    [DllImport("wininet.dll", SetLastError=true)]
    public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
}
"@
Add-Type $winInet
[RefreshIESettings]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0)

# Log to file
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "$timestamp - $message"

# Show popup on top of all windows
[System.Windows.Forms.MessageBox]::Show(
    $message,
    "Proxy Toggle",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information,
    [System.Windows.Forms.MessageBoxDefaultButton]::Button1,
    [System.Windows.Forms.MessageBoxOptions]::ServiceNotification
)

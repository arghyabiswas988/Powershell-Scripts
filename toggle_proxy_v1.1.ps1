Add-Type -AssemblyName System.Windows.Forms

# Define registry path
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

# Ensure required properties exist
if (-not (Get-ItemProperty -Path $regPath -Name AutoDetect -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $regPath -Name AutoDetect -PropertyType DWord -Value 1 | Out-Null
}
if (-not (Get-ItemProperty -Path $regPath -Name ProxyEnable -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $regPath -Name ProxyEnable -PropertyType DWord -Value 0 | Out-Null
}

# Read current values
$settings = Get-ItemProperty -Path $regPath
$autoDetect = $settings.AutoDetect
$proxyEnable = $settings.ProxyEnable
$proxyServer = $settings.ProxyServer
$proxyOverride = $settings.ProxyOverride

# Toggle logic
if ($autoDetect -eq 1 -and $proxyEnable -eq 0) {
    # Switch to Proxy Server
    Set-ItemProperty -Path $regPath -Name AutoDetect -Value 0
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value "http://proxy.company.com:8080"
    Set-ItemProperty -Path $regPath -Name ProxyOverride -Value "<local>"
    $message = "Switched to Proxy Server mode with same proxy for all protocols."
}
else {
    # Switch to Automatically Detect Settings
    Set-ItemProperty -Path $regPath -Name AutoDetect -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0
    $message = "Switched to Automatically Detect Settings mode."
}

# Notify system of the change
rundll32.exe inetcpl.cpl,ClearMyTracksByProcess 8

# Show popup on top of all windows
[System.Windows.Forms.MessageBox]::Show(
    $message,
    "Proxy Toggle",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information,
    [System.Windows.Forms.MessageBoxDefaultButton]::Button1,
    [System.Windows.Forms.MessageBoxOptions]::ServiceNotification
)

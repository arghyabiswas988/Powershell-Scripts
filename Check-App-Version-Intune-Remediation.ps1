<#
.SYNOPSIS
Detection script to check if Google Chrome and Microsoft Edge are installed
and retrieve their installed versions.

.DESCRIPTION
This script scans the system uninstall registry locations to identify the
presence of Google Chrome and Microsoft Edge. If found, it outputs the
application name along with the installed version.

The script is designed for use with Microsoft Intune Remediations and follows
best practices:
- Read-only detection (no changes made)
- Clean output for reporting
- Uses exit codes for compliance status

Exit Codes:
0 - One or more applications found (Compliant)
1 - No applications found (Non-compliant)

.AUTHOR
Arghya Biswas

.VERSION
1.0

.DATE
2026-04-07
#>

$apps = @(
    "Google Chrome",
    "Microsoft Edge"
)

$installedApps = @()

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $regPaths) {
    if (Test-Path $path) {
        $installedApps += Get-ItemProperty $path | Where-Object {
            $_.DisplayName -and ($apps -contains $_.DisplayName)
        }
    }
}

if ($installedApps.Count -gt 0) {

    # Remove duplicates and pick latest version
    $finalApps = $installedApps |
        Group-Object DisplayName |
        ForEach-Object {
            $_.Group | Sort-Object DisplayVersion -Descending | Select-Object -First 1
        }

    foreach ($app in $finalApps) {
        Write-Output "$($app.DisplayName) - $($app.DisplayVersion)"
    }

    exit 0
}
else {
    Write-Output "Chrome and Edge not found"
    exit 1
}

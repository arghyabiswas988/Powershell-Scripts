# Define the name of the application you want to search for
$applicationName = "ENGAGE 3.6.2"
#$applicationName = "PowerToys (Preview) x64"

# Define registry paths for both 32-bit and 64-bit installations
$uninstallPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

# Add current user registry path

$currentUserPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
#>

#$currentUserPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"


# Function to search for uninstall command
function SearchUninstallCommand {
    param (
        [string]$path
    )

    $uninstallKeys = Get-ChildItem $path | Where-Object { $_.PSChildName -ne $null }

    foreach ($key in $uninstallKeys) {
        $displayName = (Get-ItemProperty $key.PSPath).DisplayName

        # Check if the display name matches the application name
        if ($displayName -match $applicationName) {
            $uninstallCommand = (Get-ItemProperty $key.PSPath).UninstallString

            # Display the uninstall command
            Write-Host "Uninstall Command for '$displayName': $uninstallCommand"
        }
    }
}

# Search 32-bit and 64-bit uninstall paths
foreach ($path in $uninstallPaths) {
    SearchUninstallCommand $path
}

# Search current user uninstall path

foreach ($path in $currentUserPaths) {
SearchUninstallCommand $path
}
#>
#SearchUninstallCommand $currentUserPath
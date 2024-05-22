function Uninstall-App {
    [CmdletBinding()]
    param (
        [string]$AppName
    )

    # Get the list of installed packages
    $packages = Get-Package

    # If AppName is not provided, list the packages and ask the user to select one
    if (-not $AppName) {
        $packages | ForEach-Object {
            Write-Host "$($_.Name) - $($_.ProviderName)"
        }

        $AppName = Read-Host "Enter the name of the app you want to uninstall"
    }

    # Filter the package list to find the package with the given name
    $packageToUninstall = $packages | Where-Object { $_.Name -eq $AppName }

    if ($packageToUninstall) {
        $packageToUninstall | ForEach-Object {
            try {
                Uninstall-Package -Name $_.Name -ProviderName $_.ProviderName -Force -ErrorAction Stop
                Write-Host "$($_.Name) has been uninstalled successfully."
            } catch {
                Write-Host "Failed to uninstall $($_.Name). Error: $_"
            }
        }
    } else {
        Write-Host "No package found with the name '$AppName'."
    }
}

# Example usage:
Uninstall-App -AppName "Teams Machine-Wide Installer"
# or simply call Uninstall-App to list and select an app
# Uninstall-App

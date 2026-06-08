$SelectedApp = $null

$choice = Show-ADTInstallationPrompt `
    -Title 'Application Selection' `
    -Message 'Select an application to install.' `
    -ButtonRightText 'App1' `
    -ButtonMiddleText 'App2' `
    -ButtonLeftText 'App3' `
    -PersistPrompt

switch ($choice) {

    'App1' {
        $SelectedApp = 'App1'
    }

    'App2' {
        $SelectedApp = 'App2'
    }

    'App3' {
        $SelectedApp = 'App3'
    }
}

Write-ADTLogEntry -Message "Selected application: $SelectedApp"

switch ($SelectedApp) {

    'App1' {
        Execute-Process -Path "$dirFiles\App1.exe"
    }

    'App2' {
        Execute-Process -Path "$dirFiles\App2.exe"
    }

    'App3' {
        Execute-Process -Path "$dirFiles\App3.exe"
    }
}

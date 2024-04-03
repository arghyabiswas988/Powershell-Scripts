function Get-ChromeExtension {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    Get-ChildItem "\\$ComputerName\c$\users\*\appdata\local\Google\Chrome\User Data\*\Extensions\*\*\manifest.json" -ErrorAction SilentlyContinue | % {
        $path = $_.FullName
        #Write-Output $path
        $_.FullName -match 'users\\(.*?)\\appdata' | Out-Null
        #Get-Content $_.FullName -Raw | ConvertFrom-Json | select @{n='ComputerName';e={$ComputerName}}, @{n='User';e={$Matches[1]}}, Name, Version, @{n='Path';e={$path}}
        Get-Content $_.FullName -Raw | ConvertFrom-Json | select Name, Version
    }
}

Get-ChromeExtension | ? name -notmatch '__msg_' | sort Name, {[version]$_.version}

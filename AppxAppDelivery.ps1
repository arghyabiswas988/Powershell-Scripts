[CmdletBinding(DefaultParameterSetName = 'Install')]
param
    (
        [Parameter(
            Mandatory = $true)]
        [string]$AppName, 
        [Parameter(
            ParameterSetName = 'Install',
            Mandatory = $true)]
        [string]$PackageFileName,  
        [Parameter(
            ParameterSetName = 'Install',
            Mandatory = $true)]
        [string]$LicenseFileName, 
        [Parameter(
            ParameterSetName = 'Install',
            Mandatory = $false)]
        [string]$DependencyFileName,
        [Parameter(
            ParameterSetName = 'Uninstall')]
        [switch]$Uninstall
       
    )

<# ==========================================================================================================================================================================
Copyright (c) 2023 Microsoft
Script to install or uninstall any AppxPackage via Add-AppxPackage. Replace user-scoped app if applicable.
=============================================================================
#>

#region ComputerGenerated-LoggingFunctions
function Write-CMSLog
{
    <#
        .SYNOPSIS
        Logs a message.

        .DESCRIPTION
        Logs a message.

        .PARAMETER Message
        The message to log.

        .EXAMPLE
        Write-CMSLog -Message value

        .INPUTS
        [string]

        .OUTPUTS
        [string]
    #>

    param
    (
        [Parameter(Mandatory,
                   Position = 0,
                   HelpMessage = 'Text to write to the log.')]
        [string]$Message,
        [string]$Prefix = 'Main'
    )

    Write-Verbose -Message ('[{0} UTC]:[{1}]: {2}' -f ((Get-Date).ToUniversalTime().ToString('MM/dd/yyyy HH:mm:ss')), $Prefix, $Message) -Verbose
}

function New-CMSLoggingPath
{
    <#
        .SYNOPSIS
        Tests if the logging path exists and creates it if not.

        .DESCRIPTION
        Tests if the logging path exists and creates it if not.

        .PARAMETER DirectoryPath
        The directory path to test and create.

        .EXAMPLE
        New-CMSLoggingPath -DirectoryPath value

        .INPUTS
        [string]

        .OUTPUTS
        [bool]
    #>

    param
    (
        [Parameter(Position=0,
                   Mandatory)]
        [string]$DirectoryPath
    )

    $prefix = $myInvocation.MyCommand.Name

    try
    {
        if (!(Test-Path -Path $DirectoryPath))
        {
            Write-CMSLog -Prefix $prefix -Message ('Logging directory [{0}] was not found. Attempting to create.' -f $DirectoryPath)
            $null = New-Item -ItemType Directory -Path $DirectoryPath -Force -ErrorAction Stop
            Write-CMSLog -Prefix $prefix -Message 'Logging directory creation was successful.'
            return $true
        }

        Write-CMSLog -Prefix $prefix -Message ('Logging directory [{0}] was found. Skipping creation.' -f $DirectoryPath)
        return $true
    }
    catch
    {
        Write-Error -Message ('Failure encountered attempting to create logging directory [{0}]. Exception: {1}' -f $DirectoryPath, $_.Exception.Message)
        return $false
    }
}
function Remove-CMSLogFile
{
    <#
        .SYNOPSIS
        Remove outdated log files from the MMD logging folder.

        .DESCRIPTION
        Removes outdated log files from MMD logging folder that are older than X days.
        
        .PARAMETER LogPrefix
        Prefix to use for the log file name.
        
        .PARAMETER Days
        # of days to retain. Anything older than the specified # of days will be removed.
        
        .EXAMPLE
        Remove-LogFiles -LogPrefix ContosoLogging -Days 5
    #>
    
    param 
    (
        [Parameter(Mandatory,
                   Position = 0)]
        [string]$LogPrefix,
        [Parameter(Position = 1)]
        [int]$Days = 5
    )

    $prefix = $myInvocation.MyCommand.Name

    [string]$logPath = ('{0}\Modern-Workplace-Logs\' -f $env:SystemDrive)
    
    # Remove old logs
    $logFiles = Get-ChildItem -Path $logpath -Filter ('{0}*.log' -f $LogPrefix) -File | Where-Object {$_.CreationTime -lt (Get-Date).AddDays((-1 * $Days))}
    
    foreach ($logFile in $logFiles) 
    {
        try 
        {
            $null = Remove-Item -Path ('{0}{1}' -f $logPath, $logFile) -Force -Confirm:$false -ErrorAction Stop
            Write-CMSLog -Prefix $prefix -Message ('Removed old log file [{0}]' -f $logFile)
        }
        catch 
        {
            Write-Error -Message ('Unable to remove old log file [{0}]. Exception: [{1}]' -f $logFile, $_.Exception.Message)
            continue
        }
    }
}

function Start-CMSLogging
{
    <#
        .SYNOPSIS
        Starts logging in the Modern-Workplace-Logs folder. Uses Start-Transcript.

        .DESCRIPTION
        Starts logging in the Modern-Workplace-Logs folder. Uses Start-Transcript.

        .PARAMETER LogPrefix
        Prefix to use for the log file name.
        
        .EXAMPLE
        Start-CMSLogging -LogPrefix Log1
        
        .INPUTS
        [System.String]
    #>
    
    param
    (
        [Parameter(Mandatory,
                   Position = 0)]
        [string]$LogPrefix
    )
    
    # Generates a standard name for log files
    [string]$loggingPath = ('{0}\Modern-Workplace-Logs' -f $env:SystemDrive)
    [bool]$loggingPathExists = New-CMSLoggingPath -DirectoryPath $loggingPath
    
    if (!$loggingPathExists)
    {
        # Unable to log results. Exiting.
        exit 1
    }
    
    [string]$logFile = Join-Path -Path $loggingPath -ChildPath ('{0}-{1}.log' -f $LogPrefix, ((Get-Date).ToFileTimeUtc()))
    $loggingOutput = Start-Transcript -Path $logFile -IncludeInvocationHeader
    Write-Verbose -Message ('[{0}]' -f $loggingOutput)
}
#endregion

function Remove-AppxPkg {
    [CmdletBinding()]
    param
    (
        [string]$AppName
    )

    # Attempt to remove AppxPackage
    Write-CMSLog -Message ('Processing removal of [{0}].' -f $AppName)
    $appxInstalled = Get-AppxPackage -Name $AppName -AllUsers

    try
    {
        # List users with the AppxPackage installed
        Write-CMSLog -Message ("Found the following users with AppxPackage '{0}':" -f ($AppName)) 
        foreach ($appxInstalledUserInfo in $appxInstalled.PackageUserInformation) {
            $appxInstalledUser = ($appxInstalledUserInfo | Select-Object -ExpandProperty UserSecurityId).UserName
            Write-CMSLog -Message ('User: [{0}], InstallState: [{1}]' -f $appxInstalledUser, $appxInstalledUserInfo.InstallState)
        }

        Write-CMSLog -Message ('Removing AppxPackage: [{0}].' -f $AppName)
        $appxInstalled | Remove-AppxPackage -AllUsers -ErrorAction Stop
    }
    catch {
        
        if ( $_.Exception.Message -like '*HRESULT: 0x80073CF1*') {
            Write-CMSLog -Message ('AppxPackage removal failed. Error: 0x80073CF1. The manifest for [{0}] needs to be re-registered before it can be removed.') -f $AppName
        }
        elseif ($_.Exception.Message -like '*failed with error 0x80070002*') {
            Write-CMSLog -Message 'AppxPackage removal failed. Error 0x80070002'
        }
        else {
            Write-CMSLog -Message ('Removing AppxPackage [{0}] failed.' -f $AppName)
            Write-CMSLog -Message $_.Exception.Message
        }

        return $false
    }
    
    # Test removal was successful
    $testAppxInstalled = Get-AppxPackage -Name $AppName -AllUsers

    if ([string]::IsNullOrEmpty($testAppxInstalled)) {
        Write-CMSLog -Message ('All instances of [{0}] were removed succesfully.' -f $AppName)
        return $true
    }
    else {
        Write-CMSLog -Message ('Removing AppxPackage [{0}] for all users was not succesful' -f $AppName)
        return $false
    }
}

function Remove-AppxProvisionedPkg {
    [CmdletBinding()]
    param
    (
        [string]$AppPackageName
    )

    Write-CMSLog -Message ('Processing removal of [{0}].' -f $AppPackageName)
    try
    {
        Remove-AppxProvisionedPackage -Online -PackageName $AppPackageName -ErrorAction Stop
    }
    catch
    {
        Write-CMSLog -Message ('Failed to remove [{0}], exception message below:' -f $AppPackageName)
        Write-CMSLog -Message $_.Exception.Message
        return $false
    }

    [bool]$results = Get-AppxProvisionedPackage -Online | Where-Object -Property PackageName -EQ -Value $AppPackageName
    return $results
}

function Test-AppxPkg {
    [CmdletBinding()]
    param
    (
        [string]$AppName
    )

    [bool]$results = Get-AppxPackage -Name $AppName -AllUsers
    return $results
}

function Test-AppxProvisionedPkg {
    [CmdletBinding()]
    param
    (
        [string]$AppName
    )

    [bool]$results = Get-AppxProvisionedPackage -Online | Where-Object -Property DisplayName -EQ -Value $AppName
    return $results
}


function Get-DependentPackages {
[CmdletBinding()]
    param
    (
        [string]$DependencyFilePath
    )

    [string[]]$results = Get-Content -Path $DependencyFilePath
    return $results
}

function Get-DependencyPackagePath {
[CmdletBinding()]
    param
    (
        [string]$DependencyFilePath
    )

    Write-CMSLog -Message ('Dependency file path is [{0}]' -f $DependencyFilePath)
    Write-CMSLog -Message ('Checking for dependencies')

    $HasDependencies = Test-Path -Path $DependencyFilePath
    
    if ($HasDependencies -eq $true)
    {
        [string[]]$results = Get-Content -Path $DependencyFilePath
        Write-CMSLog -Message ('Dependency packages: [{0}]' -f $($results -join ", "))
    }
    else 
    {
        Write-CMSLog -Message ('Dependency file specified but no dependency file found at [{0}]' -f $DependencyFilePath)
    }

    
    return $results
}


function Install-AppxProvisionedPkg {
    [CmdletBinding()]
    param
    (
        [string]$AppName,
        [string]$PackageFileName,
        [string]$LicenseFileName,
        [string]$DependencyFileName
    )

    $PackagePath = "$($PSScriptRoot)\$($PackageFileName)"
    $LicenseFilePath = "$($PSScriptRoot)\$($LicenseFileName)"    


    #Write-CMSLog -Message 'WinGet is installed, proceeding.'
    Write-CMSLog -Message ('Installing [{0}].' -f $AppName)
    Write-CMSLog -Message ('Local package path is [{0}]' -f $PackagePath)
    Write-CMSLog -Message ('License file path is [{0}]' -f $LicenseFilePath)
    

    if (-not ([string]::IsNullOrEmpty($DependencyFileName)))
    {
        $DependencyFilePath = "$($PSScriptRoot)\$($DependencyFileName)"
        $DependencyPackagePath = Get-DependencyPackagePath -DependencyFilePath $DependencyFilePath        
    }    
    
    #Set-Location -Path $WinGetPath
    #.\winget.exe install --id $AppId --scope machine --verbose-logs --accept-package-agreements --accept-source-agreements --force --disable-interactivity

    try
    {
        if ($null -eq $DependencyPackagePath)
        {
            $null = Add-AppxProvisionedPackage -Online -PackagePath $PackagePath -LicensePath $LicenseFilePath -ErrorAction Stop 
        }
        else 
        {
            $null = Add-AppxProvisionedPackage -Online -PackagePath $PackagePath -LicensePath $LicenseFilePath -DependencyPackagePath $DependencyPackagePath -ErrorAction Stop 
        }
    }
    catch
    {
        Write-CMSLog -Message ('Failed to install [{0}], exception message below:' -f $AppPackageName)
        Write-CMSLog -Message $_.Exception.Message
    }

    Set-Location -Path $PSScriptRoot
}

<# function Test-WinGet {
    $winGetConfig = @{
        Name = 'Microsoft.DesktopAppInstaller'
        PackageName = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
        Binary = 'winget.exe'
    }

    #results are false, only return true if successful
    $results = $false

    # Test the WinGet package and other dependencies are installed
    Write-CMSLog -Message "Testing that WinGet package and other dependencies are installed."

    try
    {
        $winGetPath = (Get-AppxPackage -AllUsers | Where-Object -Property Name -EQ -Value $winGetConfig.Name).InstallLocation | Sort-Object -Descending | Select-Object -First 1
    }
    catch
    {
        Write-CMSLog -Message 'No package found for WinGet.'
    }

    if ([string]::IsNullOrEmpty($winGetPath))
    {
        Write-CMSLog -Message 'A WinGet package was found, but the installation path was not.'
    }
    else
    {
        Write-CMSLog -Message ('The WinGet package was found at path: {0}' -f $winGetPath)
        $winGetBinaryPath = Join-Path -Path $winGetPath -ChildPath $winGetConfig.Binary

        try
        {
            Test-Path -Path $winGetBinaryPath
        }
        catch
        {
            Write-CMSLog -Message 'An error was encounted trying to validate the path to winget.exe.'
        }

        Write-CMSLog -Message ('The WinGet binary was found at path: {0}' -f $winGetBinaryPath)
        Write-CMSLog -Message 'Will now proceed with testing ability to execute winget.exe as SYSTEM.'
    }
    
    #Test WinGet running as SYSTEM
    try
    {
        Set-Location -Path $winGetPath
        $winGetTest = .\winget.exe --version
        Set-Location -Path $PSScriptRoot

        if ([string]::IsNullOrEmpty($winGetTest))
        {
            Write-CMSLog -Message 'No output was detected while testing the WinGet version.'
            Write-CMSLog -Message 'WinGet has a dependency on this VC++ redistributable 14.x when running in the SYSTEM context. Ensure VC++ redistributable 14.x or higher is installed.'
        }
        else
        {
            Write-CMSLog -Message 'The WinGet binary was validated.'
            Write-CMSLog -Message ('WinGet version is [{0}]' -f $winGetTest)
            $results = $true
        }
    }
    catch
    {
        Write-CMSLog -Message 'An error was encountered while trying to execute the WinGet binary as SYSTEM.'
    }

    return $results
} #>

<# 
function Install-WinGetMsixBundle {

        $tempPath = "$env:HOMEDRIVE\temp"
        if (-not (Test-Path -Path $temppath))
        {
            $null = New-Item -ItemType Directory -Path $tempPath
        }

        # Set $results to $false, change only if successful
        $results = $false

        try
        {
            Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile "$env:HOMEDRIVE\temp\wingetpackage.msixbundle"
        }
        catch
        {
            Write-CMSLog -Message 'Issue occurred while downloading WinGet msixbundle'
            Write-CMSLog -Message ('{0}' -f $_.Exception.Message)
        }
        try
        {
            Add-AppxProvisionedPackage -Online -PackagePath "$env:HOMEDRIVE\temp\wingetpackage.msixbundle" -SkipLicense
        }
        catch
        {
            Write-CMSLog -Message 'Issue occurred while installing WinGet msixbundle as an appx provisioned package'
            Write-CMSLog -Message ('{0}' -f $_.Exception.Message)
        }

        $testWinGetPath = Test-WinGet
        if ($testWinGetPath)
        {
            #test successful - set $results to the path we expect to get back
            $results = $testWinGetPath
        }

        return $results
}
 #>

$LogPrefix = ('AppxProvisionedPackage{0}{1}' -f $AppName, $PSCmdlet.ParameterSetName)

Start-CMSLogging -LogPrefix $LogPrefix
Remove-CMSLogFile -LogPrefix $LogPrefix -Days 5

#Check if appx is installed with no provisioning package
$installed = Test-AppxPkg -AppName $AppName
$provisioned = Test-AppxProvisionedPkg -AppName $AppName

if ($installed -and $provisioned)
{
    if (-not $Uninstall)
    {
        Write-CMSLog -Message ('[{0}] is both provisioned and installed for at least one user. No action needed.' -f $AppName)
        exit 0
    }
}

#If script hasn't quit, not in ideal state
if ($installed)
{
    #Only installed for user, if not using uninstall switch
    Write-CMSLog -Message ('[{0}] is installed for at least one user. Removing user scope package.' -f $AppName)
    $removeAppxPkg = Remove-AppxPkg -AppName $AppName

    if (-not $removeAppxPkg)
    {
        Write-CMSLog -Message ('Failed to remove the user-scoped appx package.')
        exit 1
    }


    if ($Uninstall -and $provisioned)
    {
        #Also remove provisioned package
        $AppPackageName = (Get-AppxProvisionedPackage -Online | Where-Object -Property DisplayName -EQ -Value $AppName).PackageName

        if ([string]::IsNullOrEmpty($AppPackageName))
        {
            Write-CMSLog -Message ('Unable to parse the AppxProvisionedPackage PackageName [{0}], it may have already been removed.' -f $AppName)
            exit 0
        }
        
        $removeAppxProvisionedPkg = Remove-AppxProvisionedPkg -AppPackageName $AppPackageName
        if (-not $removeAppxProvisionedPkg)
        {
            Write-CMSLog -Message ('Failed to remove the provisioned appx package.')
            exit 1
        }

        Write-CMSLog -Message ('Uninstalled user-scoped and provisioned packages successfully.')
        exit 0
    }
}
else
{
    if ($Uninstall)
    {
        Write-CMSLog -Message ('[{0}] is not provisioned or installed for any user, no action required.' -f $AppName)
        exit 0
    }
}

#Now time to re-install Company Portal in machine scope as an appx provisioned package
Write-CMSLog -Message ('Ready to install [{0}] as a packaged AppxBundle.' -f $AppName)
#Write-CMSLog -Message ('Checking if WinGet is installed and usable by SYSTEM.')

#$winGetTestOne = Test-WinGet

<# if (-not $winGetTestOne)
{
    Write-CMSLog -Message 'WinGet is not installed and usable by SYSTEM.'
    Write-CMSLog -Message 'Attempting to install WinGet and test functionality.'
    $winGetTestTwo = Install-WinGetMsixBundle

    if (-not $winGetTestTwo)
    {
        Write-CMSLog -Message ('WinGet failed to install and allow execution by SYSTEM. Cannot proceed.')
        exit 1
    }
} #>

#$winGetPath = (Get-AppxPackage -AllUsers | Where-Object -Property Name -EQ -Value 'Microsoft.DesktopAppInstaller').InstallLocation | Sort-Object -Descending | Select-Object -First 1

Write-CMSLog -Message ('Attempting to install package...')

Install-AppxProvisionedPkg -AppName $AppName -PackageFileName $PackageFileName -LicenseFileName $LicenseFileName -DependencyFileName $DependencyFileName

Clear-Variable -Name installed
Clear-Variable -Name provisioned

$installed = Test-AppxPkg -AppName $AppName
$provisioned = Test-AppxProvisionedPkg -AppName $AppName

if ($installed -and $provisioned)
{
    Write-CMSLog -Message ('[{0}] is installed and provisioned.' -f $AppName)
    exit 0
}

Write-CMSLog -Message ('[{0}] provisioning status is [{1}]; install status is [{2}].' -f $AppName, $provisioned, $installed)

Stop-Transcript
exit 1

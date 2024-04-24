
[CmdletBinding(DefaultParameterSetName = 'Install')]
param
    (
        [Parameter(
            Mandatory = $false)]
        [string]$AppName, 
        [Parameter(
            ParameterSetName = 'Install',
            Mandatory = $false)]
        [string]$PackageFileName,  
        [Parameter(
            ParameterSetName = 'Uninstall')]
        [switch]$Uninstall
       
    )

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

    [string]$logPath = ('{0}\ProgramData\Microsoft\IntuneManagementExtension\Logs\' -f $env:SystemDrive)
    
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
    [string]$loggingPath = ('{0}\ProgramData\Microsoft\IntuneManagementExtension\Logs' -f $env:SystemDrive)
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

function Install-AppxProvisionedPkg {
    [CmdletBinding()]
    param
    (
        [string]$AppName,
        [string]$PackageFileName
        #[string]$LicenseFileName,
        #[string]$DependencyFileName
    )

    $PackagePath = "$($PSScriptRoot)\$($PackageFileName)"
    #$LicenseFilePath = "$($PSScriptRoot)\$($LicenseFileName)"    


    #Write-CMSLog -Message 'WinGet is installed, proceeding.'
    Write-CMSLog -Message ('Installing [{0}].' -f $AppName)
    Write-CMSLog -Message ('Local package path is [{0}]' -f $PackagePath)
    #Write-CMSLog -Message ('License file path is [{0}]' -f $LicenseFilePath)
    

   
    
    #Set-Location -Path $WinGetPath
    #.\winget.exe install --id $AppId --scope machine --verbose-logs --accept-package-agreements --accept-source-agreements --force --disable-interactivity

    try
    {
        if ($null -eq $DependencyPackagePath)
        {
            $null = Add-AppxProvisionedPackage -Online -PackagePath $PackagePath -SkipLicense -ErrorAction Stop 
        }
        else 
        {
            $null = Add-AppxProvisionedPackage -Online -PackagePath $PackagePath -ErrorAction Stop 
        }
    }
    catch
    {
        Write-CMSLog -Message ('Failed to install [{0}], exception message below:' -f $AppPackageName)
        Write-CMSLog -Message $_.Exception.Message
    }

    Set-Location -Path $PSScriptRoot
}

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

Write-CMSLog -Message ('Attempting to install package...')

Install-AppxProvisionedPkg -AppName $AppName -PackageFileName $PackageFileName

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

@echo off
setlocal
set "APPNAME=BarTender"
set "APPVENDOR=Seagull Scientific"
set "APPVERSION=11.3.8"
REM set "OldAppName=IDERA ERStudio Data Architect 20.0"
REM set "OldAppVersion=20.0.1.12769"
set "SETUPEXE=%~dp0BT2022_R8_216048_Full_x64.exe"
set "INSTALLDIR=%ProgramData%\%APPNAME%_%APPVERSION%"
REM set "MSI=snowflake-cli-3.12.0.0-x86_64.msi"
REM set "MST=SnowflakeInc_SnowflakeCLI_3.12.0.0_R01_x64_EN_M.mst"
set "MSICODE={B29BBA59-0559-4B15-B221-5F1BC3FFCBC9}"
REM set "processName=MyPCSelfHelp.exe"

set "LOGFOLDER=%ProgramData%\Microsoft\IntuneManagementExtension\Logs"
if not exist "%LOGFOLDER%" MKDIR "%LOGFOLDER%"

if /I "%~1"=="Uninstall" goto :Uninstall

REM =====================================================
REM Pre Installation
REM =====================================================
IF defined OldAppName (
    echo Checking for older versions,please wait...
    REM Get the exact version using PowerShell
    for /f "delims=" %%A in ('powershell -Command "(Get-Package | Where-Object { $_.Name -ieq '%OldAppName%' -and $_.Version -eq '%OldAppVersion%' }).Version.ToString()"') do (
        set "packageVersion=%%A"
    )

    REM Check and uninstall
    if "%packageVersion%"=="%OldAppVersion%" (
        echo Found matching version. Uninstalling...
        "C:\ProgramData\Package Cache\{dfa0a0bc-bd96-44f6-83b3-2f3d247dcb07}\ERDA.exe" /uninstall /quiet
	    if exist "C:\ProgramData\Embarcadero" RD /S /Q "C:\ProgramData\Embarcadero"
        ) else (
        echo Version not matched. Skipping uninstallation.
        )
    )

REM =====================================================
REM INSTALLATION
REM =====================================================
echo Installing %APPVENDOR% %APPNAME% v%APPVERSION%, Please wait...
"%SETUPEXE%" /exenoui /exelog "%LOGFOLDER%\%APPNAME%_%APPVERSION%_Install.log" FEATURE=BarTender
set msierror=%errorlevel%
if %msierror%==0 goto :PostInstall
if %msierror%==259 goto :PostInstall
if %msierror%==1641 goto :PostInstall
if %msierror%==3010 goto :PostInstall

goto :ERROR

REM =====================================================
REM post Installation
REM =====================================================

:PostInstall
@echo Successfully Installed %APPVENDOR% %APPNAME% v%APPVERSION%.
REM If exist"C:\Users\Public\Desktop\ERStudio Data Architect 20.8.lnk" del /f /q "C:\Users\Public\Desktop\ERStudio Data Architect 20.8.lnk"
REM xcopy "%~dp0concurrent_527244 (1).slip" "C:\ProgramData\Embarcadero\" /S /I /Y
REM xcopy "%~dp0concurrent_533097 (1).slip" "C:\ProgramData\Embarcadero\" /S /I /Y

goto :Einde

REM =====================================================
REM Main Uninstallation
REM =====================================================

:Uninstall

REM =====================================================
REM Pre Uninstallation
REM =====================================================
IF defined processName (
    REM Check if the process is running
    tasklist /FI "IMAGENAME eq %processName%" | find /I "%processName%" >nul
    if %ERRORLEVEL%==0 (
        echo %processName% is running. Attempting to terminate...
        taskkill /F /IM %processName%
    ) else (
        echo %processName% is not running.
    )
)

REM =====================================================
REM Uninstallation
REM =====================================================

echo Uninstalling %APPVENDOR% %APPNAME% v%APPVERSION%, Please wait...
MsiExec.exe /x %MSICODE% /l*v "%LOGFOLDER%\%APPNAME%_%APPVERSION%_Uninstall.log" REBOOT=ReallySuppress /qn
set msierror=%errorlevel%
if %msierror%==0 goto :PostUninstall
if %msierror%==259 goto :PostUninstall
if %msierror%==1641 goto :PostUninstall
if %msierror%==3010 goto :PostUninstall

goto :ERROR

REM =====================================================
REM Post Uninstallation
REM =====================================================

:PostUninstall
@echo Successfully Uninstalled %APPVENDOR% %APPNAME% v%APPVERSION%.

@echo Uninstallaing Microsoft SQL Server 2019 Express, please wait... 
"%~dp0%SQL_Express\SETUP.EXE" /q /ACTION=Uninstall /FEATURES=SQL,AS,RS,IS,Tools /INSTANCENAME=BARTENDER

@echo Uninstallaing Microsoft SQL Server 2012 Native Client, please wait... 
MsiExec.exe /x {9D93D367-A2CC-4378-BD63-79EF3FE76C78} REBOOT=ReallySuppress /qb

@echo Uninstallaing Microsoft SQL Server 2014 Express LocalDB, please wait...
MsiExec.exe /x {BAF67399-85CD-4555-9B49-1F80EB921C35} REBOOT=ReallySuppress /qb

@echo Uninstallaing Microsoft OLE DB Driver for SQL Server, please wait...
MsiExec.exe /x {9AA0AFFA-EDB6-4B66-9FD7-BBC828D88B47} REBOOT=ReallySuppress /qb

@echo Uninstallaing Microsoft ODBC Driver 17 for SQL Server, please wait...
MsiExec.exe /x {787F8536-654C-4DD4-AD3F-22B529F8F339} REBOOT=ReallySuppress /qb
goto :Einde

:Error
@echo Error Code is %msierror% if exist %LogFile% type %LogFile%
goto :Einde

endlocal

:Einde
@echo Job ended at %date% %Time%
Exit %msierror%

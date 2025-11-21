@echo off
:: Check if running as admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo   ERROR: This script must be run as administrator.
    echo   Right-click and choose "Run as administrator"
    echo ========================================
    pause
    exit /b
)

setlocal

echo.
:: Add UpgradeEligibility for current user
reg add "HKCU\SOFTWARE\Microsoft\PCHC" /v "UpgradeEligibility" /t REG_DWORD /d 1 /f

:: Allow upgrades with unsupported TPM or CPU
reg add "HKLM\SYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d 1 /f

:: Bypass checks in LabConfig
reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d 1 /f

:: Delete compatibility flags
reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\CompatMarkers" /f 2>NUL
reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Shared" /f 2>NUL
reg.exe delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TargetVersionUpgradeExperienceIndicators" /f 2>NUL

:: Add HwReqChkVars
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\HwReqChk" /f /v HwReqChkVars /t REG_MULTI_SZ /s , /d "SQ_SecureBootCapable=TRUE,SQ_SecureBootEnabled=TRUE,SQ_TpmVersion=2,SQ_RamMB=8192,"

echo Registry changes applied successfully.

echo.
echo === Step 2: Mount ISO File via PowerShell ===
echo Scanning folder: %~dp0
cd /d %~dp0
dir /b *.iso
for %%i in (*.iso) do (
    set "ISOPath=%%~fi"
    echo Found ISO: %%~fi
    goto :foundiso
)
echo ERROR: No ISO file found in this folder.
goto :end

:foundiso
powershell -NoProfile -Command ^
    "Mount-DiskImage -ImagePath '%ISOPath%' -PassThru | Get-Volume | Select -ExpandProperty DriveLetter > driveletter.txt"

if not exist driveletter.txt (
    echo ERROR: Failed to mount ISO.
    goto :end
)

:: Step 3 - Find Mounted ISO Drive
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\setup.exe" (
        set "ISODrive=%%d:"
        goto foundsetup
    )
)

echo ERROR: setup.exe not found on any drive. Exiting.
goto :end

:foundsetup
echo Found setup.exe on drive %ISODrive%
echo Launching setup...
"%ISODrive%\setup.exe" /auto upgrade /dynamicupdate disable /eula accept /showoobe none


:end
endlocal
pause

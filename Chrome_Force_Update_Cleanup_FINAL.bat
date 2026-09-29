@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Google Chrome - Force Update + Cleanup
color 0A

echo ============================================================
echo        GOOGLE CHROME FORCE UPDATE + CLEANUP
echo ============================================================
echo.
echo [1] Detect Chrome
echo [2] Close Chrome
echo [3] Clear cache and cookies
echo [4] Trigger Google updater
echo [5] Wait for update
echo [6] Verify version
echo [7] Install latest Google Chrome if needed
echo [8] Verify again
echo.
echo Bookmarks, passwords, extensions and profiles are preserved.
echo ============================================================
echo.

:: ADMIN
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting Administrator privileges...
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ============================================================
:: [1] DETECT CHROME
:: ============================================================
echo.
echo ============================================================
echo [1/8] CHECKING CHROME
echo ============================================================
echo.

set "CHROME_EXE="

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%LocalAppData%\Google\Chrome\Application\chrome.exe"

if not defined CHROME_EXE (
    echo Chrome is NOT installed.
    goto INSTALL_LATEST
)

echo Chrome found:
echo %CHROME_EXE%
echo.

:: CORRECT VERSION CHECK - IMPORTANT
for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "(Get-Item -LiteralPath ''%CHROME_EXE%'').VersionInfo.FileVersion" 2^>nul') do set "OLD_VERSION=%%A"

:: Fallback using WMI/CIM
if not defined OLD_VERSION (
    for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "$x=Get-CimInstance Win32_Process -Filter \"Name='chrome.exe'\" -ErrorAction SilentlyContinue; if($x){$x[0].ExecutablePath}" 2^>nul') do set "TEMP_PATH=%%A"
)

if not defined OLD_VERSION (
    :: Use Windows file version command through PowerShell with environment variable
    set "CHROME_VERSION_PATH=%CHROME_EXE%"
    for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "$p=$env:CHROME_VERSION_PATH; if(Test-Path -LiteralPath $p){(Get-Item -LiteralPath $p).VersionInfo.ProductVersion}"') do set "OLD_VERSION=%%A"
)

if not defined OLD_VERSION set "OLD_VERSION=UNKNOWN"

echo Current Chrome version: %OLD_VERSION%
echo.

:: ============================================================
:: [2] CLOSE CHROME
:: ============================================================
echo ============================================================
echo [2/8] CLOSING CHROME
echo ============================================================
echo.

taskkill /F /IM chrome.exe >nul 2>&1
timeout /t 5 /nobreak >nul

echo Chrome closed.
echo.

:: ============================================================
:: [3] CACHE + COOKIES
:: ============================================================
echo ============================================================
echo [3/8] CLEANING CACHE AND COOKIES
echo ============================================================
echo.

set "USERDATA=%LocalAppData%\Google\Chrome\User Data"

if exist "%USERDATA%" (
    for /d %%P in ("%USERDATA%\*") do (
        if exist "%%P\Cache" rd /s /q "%%P\Cache" 2>nul
        if exist "%%P\Code Cache" rd /s /q "%%P\Code Cache" 2>nul
        if exist "%%P\GPUCache" rd /s /q "%%P\GPUCache" 2>nul
        if exist "%%P\Service Worker\CacheStorage" rd /s /q "%%P\Service Worker\CacheStorage" 2>nul
        if exist "%%P\Network\Cookies" del /f /q "%%P\Network\Cookies" 2>nul
        if exist "%%P\Network\Cookies-journal" del /f /q "%%P\Network\Cookies-journal" 2>nul
    )
)

echo Cache cleaned.
echo Cookies cleaned.
echo NOTE: Website sessions may require sign-in again.
echo.

:: ============================================================
:: [4] GOOGLE UPDATE
:: ============================================================
echo ============================================================
echo [4/8] STARTING GOOGLE CHROME UPDATE SERVICE
echo ============================================================
echo.

sc start gupdate >nul 2>&1
sc start gupdatem >nul 2>&1

schtasks /Run /TN "GoogleUpdateTaskMachineCore" >nul 2>&1
schtasks /Run /TN "GoogleUpdateTaskMachineUA" >nul 2>&1

set "GOOGLE_UPDATE="

if exist "%ProgramFiles(x86)%\Google\Update\GoogleUpdate.exe" set "GOOGLE_UPDATE=%ProgramFiles(x86)%\Google\Update\GoogleUpdate.exe"
if exist "%ProgramFiles%\Google\Update\GoogleUpdate.exe" set "GOOGLE_UPDATE=%ProgramFiles%\Google\Update\GoogleUpdate.exe"
if exist "%LocalAppData%\Google\Update\GoogleUpdate.exe" set "GOOGLE_UPDATE=%LocalAppData%\Google\Update\GoogleUpdate.exe"

if defined GOOGLE_UPDATE (
    echo Google Update:
    echo %GOOGLE_UPDATE%
    echo.
    echo Triggering Chrome update...
    start "" /wait "%GOOGLE_UPDATE%" /ua /installsource scheduler
) else (
    echo Google Update executable not found.
)

echo.
echo Google Update trigger completed.
echo.

:: ============================================================
:: [5] WAIT
:: ============================================================
echo ============================================================
echo [5/8] WAITING FOR CHROME UPDATE
echo ============================================================
echo.

echo Waiting 30 seconds...
timeout /t 30 /nobreak >nul
echo Waiting another 30 seconds...
timeout /t 30 /nobreak >nul

echo Update wait completed.
echo.

:: ============================================================
:: [6] VERIFY
:: ============================================================
echo ============================================================
echo [6/8] CHECKING CHROME VERSION AFTER UPDATE
echo ============================================================
echo.

set "NEW_VERSION="
set "CHROME_VERSION_PATH=%CHROME_EXE%"

for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "$p=$env:CHROME_VERSION_PATH; if(Test-Path -LiteralPath $p){(Get-Item -LiteralPath $p).VersionInfo.ProductVersion}"') do set "NEW_VERSION=%%A"

if not defined NEW_VERSION set "NEW_VERSION=UNKNOWN"

echo Before update:
echo %OLD_VERSION%
echo.
echo After Google Update:
echo %NEW_VERSION%
echo.

if /I not "%OLD_VERSION%"=="UNKNOWN" if /I not "%NEW_VERSION%"=="UNKNOWN" if /I not "%OLD_VERSION%"=="%NEW_VERSION%" (
    echo Chrome version changed successfully.
    goto FINAL_VERIFY
)

echo Chrome version did not change.
echo Running official Google installer as fallback.
echo.

:: ============================================================
:: [7] OFFICIAL GOOGLE INSTALLER
:: ============================================================
:INSTALL_LATEST

echo ============================================================
echo [7/8] DOWNLOADING OFFICIAL GOOGLE CHROME INSTALLER
echo ============================================================
echo.

set "INSTALLER=%TEMP%\ChromeSetup_Official.exe"

if exist "%INSTALLER%" del /f /q "%INSTALLER%" >nul 2>&1

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile '%INSTALLER%'; exit 0 } catch { exit 1 }"

if errorlevel 1 (
    echo ERROR: Could not download official Chrome installer.
    pause
    exit /b 1
)

if not exist "%INSTALLER%" (
    echo ERROR: Installer file was not created.
    pause
    exit /b 1
)

echo Official Chrome installer downloaded.
echo.
echo Installing / repairing Chrome...
echo.

start "" /wait "%INSTALLER%" /silent /install

echo Installer finished.
echo Waiting 15 seconds...
timeout /t 15 /nobreak >nul

:: ============================================================
:: [8] FINAL VERIFY
:: ============================================================
:FINAL_VERIFY

echo.
echo ============================================================
echo [8/8] FINAL CHROME VERSION CHECK
echo ============================================================
echo.

set "FINAL_VERSION="
set "CHROME_EXE="

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%LocalAppData%\Google\Chrome\Application\chrome.exe"

if defined CHROME_EXE (
    set "CHROME_VERSION_PATH=%CHROME_EXE%"
    for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "$p=$env:CHROME_VERSION_PATH; if(Test-Path -LiteralPath $p){(Get-Item -LiteralPath $p).VersionInfo.ProductVersion}"') do set "FINAL_VERSION=%%A"
)

if not defined FINAL_VERSION set "FINAL_VERSION=UNKNOWN"

echo.
echo ============================================================
echo                 CHROME UPDATE RESULT
echo ============================================================
echo.
echo Previous version : %OLD_VERSION%
echo Current version  : %FINAL_VERSION%
echo.

if /I "%FINAL_VERSION%"=="UNKNOWN" (
    echo STATUS: COULD NOT VERIFY CHROME VERSION
) else if /I "%OLD_VERSION%"=="UNKNOWN" (
    echo STATUS: CHROME INSTALLED AND VERIFIED
) else if /I not "%FINAL_VERSION%"=="%OLD_VERSION%" (
    echo STATUS: UPDATED SUCCESSFULLY
) else (
    echo STATUS: VERSION DID NOT CHANGE
    echo.
    echo Possible reasons:
    echo   - Chrome is already current for this update channel
    echo   - Organization policy controls Chrome updates
    echo   - Google Update service is blocked or disabled
    echo   - Proxy / firewall is blocking the update
)

echo.

if exist "%INSTALLER%" del /f /q "%INSTALLER%" >nul 2>&1

echo ============================================================
echo CLEANUP RESULT
echo ============================================================
echo Cache            : CLEANED
echo Cookies          : CLEANED
echo Bookmarks        : PRESERVED
echo Saved passwords  : PRESERVED
echo Extensions       : PRESERVED
echo Chrome profile   : PRESERVED
echo ============================================================
echo.
echo Press any key to exit...
pause >nul

endlocal

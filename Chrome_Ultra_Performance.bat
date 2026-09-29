@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Chrome Ultra Performance & Network Optimizer
color 0A

:: Chrome Ultra Performance & Network Optimizer
:: Run as Administrator.

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo.
    echo ============================================================
    echo  PLEASE RUN THIS FILE AS ADMINISTRATOR
    echo ============================================================
    echo Right-click the BAT file ^> Run as administrator.
    echo.
    pause
    exit /b 1
)

set "LOG=%~dp0Chrome_Ultra_Performance_Log.txt"
set "BACKUP=%~dp0Chrome_Ultra_Performance_Backup.txt"

:MENU
cls
echo ============================================================
echo          CHROME ULTRA PERFORMANCE TOOL
echo ============================================================
echo.
echo  [1] Check system, Chrome and network status
echo  [2] Apply safe performance optimization
echo  [3] Network + DNS optimization
echo  [4] Clean Windows temporary files
echo  [5] Video / network diagnostic
echo  [6] Open Chrome performance pages
echo  [7] Network repair (use only when needed)
echo  [8] Apply ALL recommended optimizations
echo  [9] Restore power plan to Balanced
echo  [0] Exit
echo.
set /p "choice=Select an option: "

if "%choice%"=="1" goto INFO
if "%choice%"=="2" goto PERFORMANCE
if "%choice%"=="3" goto NETWORK
if "%choice%"=="4" goto CLEAN
if "%choice%"=="5" goto VIDEO
if "%choice%"=="6" goto CHROME
if "%choice%"=="7" goto REPAIR
if "%choice%"=="8" goto ALL
if "%choice%"=="9" goto RESTORE
if "%choice%"=="0" exit /b
goto MENU

:INFO
cls
echo ============================================================
echo SYSTEM / CHROME / NETWORK STATUS
echo ============================================================
echo.
echo Windows:
ver
echo.
echo CPU:
wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors /value 2>nul
echo.
echo RAM:
powershell -NoProfile -Command "$r=Get-CimInstance Win32_ComputerSystem; Write-Host ('{0:N1} GB installed RAM' -f ($r.TotalPhysicalMemory/1GB))"
echo.
echo C: DRIVE:
powershell -NoProfile -Command "$d=Get-CimInstance Win32_LogicalDisk -Filter ""DeviceID='C:'""; Write-Host ('Free: {0:N1} GB / Total: {1:N1} GB' -f ($d.FreeSpace/1GB),($d.Size/1GB))"
echo.
echo Chrome process:
tasklist /FI "IMAGENAME eq chrome.exe" 2>nul
echo.
echo TCP GLOBAL SETTINGS:
netsh int tcp show global
echo.
echo DNS:
ipconfig /all | findstr /i "DNS Servers"
echo.
echo Default gateway:
ipconfig | findstr /i "Default Gateway"
echo.
pause
goto MENU

:PERFORMANCE
cls
echo ============================================================
echo APPLYING SAFE PERFORMANCE OPTIMIZATION
echo ============================================================
echo.
echo [1/4] Saving current active power plan...
for /f "tokens=4" %%G in ('powercfg /getactivescheme') do set "OLDPLAN=%%G"
if defined OLDPLAN echo Previous plan: !OLDPLAN!>>"%BACKUP%"

echo [2/4] Activating Windows High Performance plan...
powercfg /setactive SCHEME_MIN
if errorlevel 1 echo Could not activate High Performance.

echo [3/4] Enabling processor performance boost mode where supported...
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1

echo [4/4] Checking storage health/free space...
powershell -NoProfile -Command "$d=Get-CimInstance Win32_LogicalDisk -Filter ""DeviceID='C:'""; if(($d.FreeSpace/$d.Size)-lt .10){Write-Host 'WARNING: C: drive has less than 10%% free space.'}else{Write-Host 'C: free space is above 10%%.'}"
echo.
echo Done. High Performance is intended mainly for plugged-in systems.
echo This does NOT increase ISP bandwidth.
echo.
pause
goto MENU

:NETWORK
cls
echo ============================================================
echo NETWORK + DNS OPTIMIZATION
echo ============================================================
echo.
echo [1] Flushing Windows DNS cache...
ipconfig /flushdns
echo.
echo [2] Enabling RSS...
netsh int tcp set global rss=enabled
echo.
echo [3] Setting TCP receive window auto-tuning to NORMAL...
netsh int tcp set global autotuninglevel=normal
echo.
echo [4] Displaying TCP settings...
netsh int tcp show global
echo.
echo DNS server changes are intentionally NOT forced.
echo Your router/ISP may provide the best DNS for your location.
echo.
pause
goto MENU

:CLEAN
cls
echo ============================================================
echo SAFE WINDOWS TEMP CLEANUP
echo ============================================================
echo.
echo This removes temporary Windows files only.
echo It does NOT clear Chrome cache.
echo.
choice /C YN /N /M "Continue? [Y/N]: "
if errorlevel 2 goto MENU

echo Cleaning user TEMP...
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1

echo Cleaning Windows TEMP...
del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rd /s /q "%%D" >nul 2>&1

echo.
echo Temporary cleanup completed.
echo.
pause
goto MENU

:VIDEO
cls
echo ============================================================
echo VIDEO / NETWORK DIAGNOSTIC
echo ============================================================
echo.
echo Enter a host to test, or press ENTER for 1.1.1.1
set /p "HOST=Host: "
if not defined HOST set "HOST=1.1.1.1"

echo.
echo -------- PING %HOST% --------
ping -n 10 %HOST%
echo.
echo -------- DNS LOOKUP google.com --------
nslookup google.com
echo.
echo -------- NETWORK CONFIG --------
ipconfig /all
echo.
echo -------- TCP GLOBAL --------
netsh int tcp show global
echo.
echo Good ping does not guarantee zero buffering.
echo Buffering can also come from Wi-Fi, ISP congestion,
echo packet loss, video CDN/server load, or video bitrate.
echo.
pause
goto MENU

:CHROME
cls
echo ============================================================
echo CHROME PERFORMANCE PAGES
echo ============================================================
echo.
echo Opening Chrome diagnostic pages...
start "" chrome.exe "chrome://gpu"
start "" chrome.exe "chrome://settings/performance"
start "" chrome.exe "chrome://extensions"
start "" chrome.exe "chrome://version"
echo.
echo In chrome://gpu, check that Video Decode is hardware accelerated
echo when your GPU and video format support it.
echo.
pause
goto MENU

:REPAIR
cls
echo ============================================================
echo NETWORK REPAIR
echo ============================================================
echo WARNING: Winsock/IP reset can require a restart.
echo Use this only when networking is malfunctioning.
echo.
choice /C YN /N /M "Continue? [Y/N]: "
if errorlevel 2 goto MENU

echo.
echo [1/3] Flushing DNS...
ipconfig /flushdns
echo.
echo [2/3] Resetting Winsock...
netsh winsock reset
echo.
echo [3/3] Resetting TCP/IP...
netsh int ip reset
echo.
echo Restart Windows after this repair.
echo.
pause
goto MENU

:ALL
cls
echo ============================================================
echo APPLY ALL SAFE RECOMMENDED OPTIMIZATIONS
echo ============================================================
echo.
echo This will:
echo  - Activate High Performance
echo  - Enable RSS
echo  - Set TCP auto-tuning to normal
echo  - Flush DNS
echo  - Clean Windows TEMP files
echo.
echo It will NOT:
echo  - Disable Windows Defender
echo  - Disable Firewall
echo  - Disable Chrome Sandbox
echo  - Delete Chrome cache
echo  - Disable hardware acceleration
echo  - Apply unsafe TCP registry hacks
echo.
choice /C YN /N /M "Continue? [Y/N]: "
if errorlevel 2 goto MENU

for /f "tokens=4" %%G in ('powercfg /getactivescheme') do echo Previous power plan: %%G>>"%BACKUP%"
powercfg /setactive SCHEME_MIN >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
ipconfig /flushdns >nul
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo %date% %time% - Full optimization completed>>"%LOG%"

echo.
echo ============================================================
echo ALL RECOMMENDED OPTIMIZATIONS COMPLETED
echo ============================================================
echo Restart Windows once after the first full run.
echo Then open Chrome and check chrome://gpu.
echo.
pause
goto MENU

:RESTORE
cls
echo ============================================================
echo RESTORE BASIC POWER SETTING
echo ============================================================
echo.
echo Setting Windows back to Balanced power mode...
powercfg /setactive SCHEME_BALANCED
if errorlevel 1 echo Could not activate Balanced.
echo.
echo Network settings are not blindly reverted because they may
echo have been configured by your administrator or ISP.
echo.
pause
goto MENU

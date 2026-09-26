@echo off
title Temp Cleanup, System Report, Power Config, Native Windows Update

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo =====================================================
    echo ERROR: Administrator privileges are required!
    echo Please right-click this script and select "Run as administrator".
    echo =====================================================
    pause
    exit /b
)

:: Define paths to create a folder on the Desktop and save the file
set "LOCAL_DIR=%USERPROFILE%\Desktop\System Info"
set "FILE_NAME=%COMPUTERNAME%.txt"
set "LOCAL_PATH=%LOCAL_DIR%\%FILE_NAME%"

if not exist "%LOCAL_DIR%" mkdir "%LOCAL_DIR%"

echo Cleaning up Temporary Files...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
del /q /f /s "C:\Windows\Prefetch\*" >nul 2>&1
echo Temp files cleared successfully.

echo.
echo Generating system report for %COMPUTERNAME%...
echo ======================================== > "%LOCAL_PATH%"
echo DEVICE NAME: %COMPUTERNAME% >> "%LOCAL_PATH%"
echo DATE GENERATED: %date% %time% >> "%LOCAL_PATH%"
echo ======================================== >> "%LOCAL_PATH%"

echo. >> "%LOCAL_PATH%"
echo --- OS AND SYSTEM INFO --- >> "%LOCAL_PATH%"
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Manufacturer" /C:"System Model" >> "%LOCAL_PATH%"

echo. >> "%LOCAL_PATH%"
echo --- PROCESSOR (CPU) --- >> "%LOCAL_PATH%"
powershell -NoProfile -Command "Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name" >> "%LOCAL_PATH%"

echo. >> "%LOCAL_PATH%"
echo --- MEMORY (RAM) --- >> "%LOCAL_PATH%"
systeminfo | findstr /C:"Total Physical Memory" >> "%LOCAL_PATH%"
echo. >> "%LOCAL_PATH%"
echo [Physical Memory Modules] >> "%LOCAL_PATH%"
powershell -NoProfile -Command "Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Manufacturer, PartNumber, @{N='Capacity(GB)';E={[math]::Round($_.Capacity / 1GB, 2)}}, Speed | Format-Table -AutoSize" >> "%LOCAL_PATH%"

echo. >> "%LOCAL_PATH%"
echo --- LOGICAL STORAGE SPACE (C:, D:, etc.) --- >> "%LOCAL_PATH%"
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID, @{N='FreeSpace(GB)';E={[math]::Round($_.FreeSpace / 1GB, 2)}}, @{N='Size(GB)';E={[math]::Round($_.Size / 1GB, 2)}} | Format-Table -AutoSize" >> "%LOCAL_PATH%"

echo. >> "%LOCAL_PATH%"
echo --- PHYSICAL DRIVES (SSD/HDD, BRAND, SERIAL, HEALTH) --- >> "%LOCAL_PATH%"
powershell -NoProfile -Command "Get-PhysicalDisk | Select-Object MediaType, @{N='Brand/Model';E={$_.FriendlyName}}, SerialNumber, HealthStatus | Format-Table -AutoSize" >> "%LOCAL_PATH%"

echo. >> "%LOCAL_PATH%"
echo --- MONITORS --- >> "%LOCAL_PATH%"
powershell -NoProfile -Command "$m = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue; if ($m) { $m | ForEach-Object { $man='Unknown'; if($_.ManufacturerName){$man=[System.Text.Encoding]::ASCII.GetString($_.ManufacturerName).Replace([char]0,[char]32).Trim()}; $mod='Unknown'; if($_.UserFriendlyName){$mod=[System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName).Replace([char]0,[char]32).Trim()}; $ser='Unknown'; if($_.SerialNumberID){$ser=[System.Text.Encoding]::ASCII.GetString($_.SerialNumberID).Replace([char]0,[char]32).Trim()}; [PSCustomObject]@{Manufacturer=$man; Model=$mod; SerialNumber=$ser} } | Format-Table -AutoSize } else { 'No monitor data found.' }" >> "%LOCAL_PATH%"

echo. >> "%LOCAL_PATH%"
echo --- KEYBOARD --- >> "%LOCAL_PATH%"
powershell -NoProfile -Command "Get-CimInstance Win32_Keyboard | Select-Object Description, Manufacturer, PNPDeviceID | Format-Table -AutoSize" >> "%LOCAL_PATH%"

echo. >> "%LOCAL_PATH%"
echo --- MOUSE --- >> "%LOCAL_PATH%"
powershell -NoProfile -Command "Get-CimInstance Win32_PointingDevice | Select-Object Description, Manufacturer, PNPDeviceID | Format-Table -AutoSize" >> "%LOCAL_PATH%"

echo. >> "%LOCAL_PATH%"
echo --- INSTALLED SECURITY PATCHES (LAST AND CURRENT MONTH ONLY) --- >> "%LOCAL_PATH%"
powershell -NoProfile -Command "$start=(Get-Date).AddMonths(-1); $cutoff=Get-Date -Year $start.Year -Month $start.Month -Day 1; Get-HotFix | Where-Object { $_.Description -match 'Security' -and $_.InstalledOn } | Where-Object { [datetime]$_.InstalledOn -ge $cutoff } | Select-Object HotFixID, InstalledOn, Description | Format-Table -AutoSize" >> "%LOCAL_PATH%"

echo.
echo Report successfully saved locally to: %LOCAL_PATH%

echo.
echo Configuring Power Settings to 3 minutes...
powercfg -change -monitor-timeout-ac 3
powercfg -change -standby-timeout-ac 3
powercfg -change -monitor-timeout-dc 3
powercfg -change -standby-timeout-dc 3

echo.
echo Resetting Windows Update Cache to fix size reporting errors...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /q /f /s "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
net start wuauserv >nul 2>&1
net start bits >nul 2>&1

echo.
echo Triggering Native Windows Update Engine...
:: Starts the built-in Windows Update scanner and installer in the background
UsoClient StartScan
timeout /t 5 /nobreak >nul
UsoClient StartInstall

echo.
echo Updates are now downloading and installing natively in the background.
echo You can check the progress in Settings -^> Windows Update.
echo All IT operations complete! 
pause

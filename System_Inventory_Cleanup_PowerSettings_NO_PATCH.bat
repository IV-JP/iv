@echo off
setlocal EnableExtensions
set "NETWORK_ROOT=\\iv-udp-lt-009\it"
set "REPORT_DIR=%NETWORK_ROOT%\System Reports"
set "COMPUTER=%COMPUTERNAME%"
set "REPORT=%REPORT_DIR%\%COMPUTER%_SystemReport.txt"
set "LOG=%REPORT_DIR%\%COMPUTER%_Cleanup_PowerLog.txt"

title System Inventory + Full Temp Cleanup + Power Settings

echo.
echo ============================================================
echo   SYSTEM INVENTORY + FULL TEMP CLEANUP + POWER SETTINGS
echo   NO PATCH INSTALLATION
 echo ============================================================
echo Computer: %COMPUTER%
echo Network : %NETWORK_ROOT%
echo.

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo [ERROR] Run this BAT as Administrator.
    pause
    exit /b 1
)

if not exist "%REPORT_DIR%" (
    echo [ERROR] Network report folder is not accessible:
    echo %REPORT_DIR%
    pause
    exit /b 2
)

>"%LOG%" echo ============================================================
>>"%LOG%" echo SYSTEM CLEANUP + POWER SETTINGS LOG
>>"%LOG%" echo Computer: %COMPUTER%
>>"%LOG%" echo Date: %date% %time%
>>"%LOG%" echo ============================================================

echo.
echo [1/3] Cleaning temporary files...
echo.

call :CleanFolder "%TEMP%" "User TEMP"
call :CleanFolder "%LOCALAPPDATA%\Temp" "LocalAppData TEMP"
call :CleanFolder "%windir%\Temp" "Windows TEMP"
call :CleanFolder "%windir%\Prefetch" "Windows Prefetch"

>>"%LOG%" echo.
>>"%LOG%" echo Cleanup completed. Files/folders currently in use were skipped.

echo.
echo [2/3] Setting monitor and sleep timeouts to 3 minutes...

powercfg -change -monitor-timeout-ac 3
if errorlevel 1 (echo [FAILED] AC monitor timeout & >>"%LOG%" echo [FAILED] AC monitor timeout) else (echo [OK] AC monitor timeout = 3 minutes & >>"%LOG%" echo [OK] AC monitor timeout = 3 minutes)

powercfg -change -standby-timeout-ac 3
if errorlevel 1 (echo [FAILED] AC sleep timeout & >>"%LOG%" echo [FAILED] AC sleep timeout) else (echo [OK] AC sleep timeout = 3 minutes & >>"%LOG%" echo [OK] AC sleep timeout = 3 minutes)

powercfg -change -monitor-timeout-dc 3
if errorlevel 1 (echo [FAILED] Battery monitor timeout & >>"%LOG%" echo [FAILED] Battery monitor timeout) else (echo [OK] Battery monitor timeout = 3 minutes & >>"%LOG%" echo [OK] Battery monitor timeout = 3 minutes)

powercfg -change -standby-timeout-dc 3
if errorlevel 1 (echo [FAILED] Battery sleep timeout & >>"%LOG%" echo [FAILED] Battery sleep timeout) else (echo [OK] Battery sleep timeout = 3 minutes & >>"%LOG%" echo [OK] Battery sleep timeout = 3 minutes)

>>"%LOG%" echo.
>>"%LOG%" echo No automatic workstation lock.
>>"%LOG%" echo No patch detection or patch installation.

echo.
echo [3/3] Collecting system inventory...

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $r=$env:REPORT; $cs=Get-CimInstance Win32_ComputerSystem; $os=Get-CimInstance Win32_OperatingSystem; $bios=Get-CimInstance Win32_BIOS; $bb=Get-CimInstance Win32_BaseBoard; $cpu=Get-CimInstance Win32_Processor; $ram=Get-CimInstance Win32_PhysicalMemory; $disk=Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3'; $gpu=Get-CimInstance Win32_VideoController; $nic=Get-CimInstance Win32_NetworkAdapter -Filter 'PhysicalAdapter=True'; $ip=Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True'; $arch=$env:PROCESSOR_ARCHITEW6432; if(-not $arch){$arch=$env:PROCESSOR_ARCHITECTURE}; $cv=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'; $lines=[System.Collections.Generic.List[string]]::new(); $lines.Add(('='*80)); $lines.Add('FULL SYSTEM INFORMATION REPORT'); $lines.Add(('='*80)); $lines.Add(('DEVICE NAME              : '+$env:COMPUTERNAME)); $lines.Add(('USER                     : '+$env:USERNAME)); $lines.Add(('DATE/TIME                : '+(Get-Date))); $lines.Add(('WINDOWS                  : '+$os.Caption)); $lines.Add(('VERSION                  : '+$os.Version)); $lines.Add(('DISPLAY VERSION          : '+$cv.DisplayVersion)); $lines.Add(('BUILD                    : '+$os.BuildNumber+'.'+$cv.UBR)); $lines.Add(('ARCHITECTURE             : '+$arch)); $lines.Add(('MANUFACTURER             : '+$cs.Manufacturer)); $lines.Add(('MODEL                    : '+$cs.Model)); $lines.Add(('DOMAIN/WORKGROUP        : '+$cs.Domain)); $lines.Add(('TOTAL RAM GB             : '+[math]::Round($cs.TotalPhysicalMemory/1GB,2))); $lines.Add(''); $lines.Add('--- BIOS ---'); $lines.Add(('BIOS MANUFACTURER        : '+$bios.Manufacturer)); $lines.Add(('BIOS VERSION             : '+$bios.SMBIOSBIOSVersion)); $lines.Add(('BIOS SERIAL              : '+$bios.SerialNumber)); $lines.Add(''); $lines.Add('--- MOTHERBOARD ---'); $lines.Add(('MANUFACTURER             : '+$bb.Manufacturer)); $lines.Add(('PRODUCT                  : '+$bb.Product)); $lines.Add(('SERIAL                   : '+$bb.SerialNumber)); $lines.Add(''); $lines.Add('--- CPU ---'); $cpu | ForEach-Object {$lines.Add(('CPU                      : '+$_.Name)); $lines.Add(('CORES                    : '+$_.NumberOfCores)); $lines.Add(('LOGICAL PROCESSORS       : '+$_.NumberOfLogicalProcessors)); $lines.Add(('MAX CLOCK MHz            : '+$_.MaxClockSpeed));}; $lines.Add(''); $lines.Add('--- MEMORY MODULES ---'); $ram | ForEach-Object {$lines.Add(('RAM                      : '+$_.Manufacturer+' | '+[math]::Round($_.Capacity/1GB,2)+' GB | '+$_.Speed+' MHz | '+$_.PartNumber));}; $lines.Add(''); $lines.Add('--- LOCAL DISKS ---'); $disk | ForEach-Object {$lines.Add(('DISK                     : '+$_.DeviceID+' | '+[math]::Round($_.Size/1GB,2)+' GB | Free '+[math]::Round($_.FreeSpace/1GB,2)+' GB | '+$_.FileSystem));}; $lines.Add(''); $lines.Add('--- GPU ---'); $gpu | ForEach-Object {$lines.Add(('GPU                      : '+$_.Name+' | Driver '+$_.DriverVersion));}; $lines.Add(''); $lines.Add('--- NETWORK ADAPTERS ---'); $nic | ForEach-Object {$lines.Add(('NIC                      : '+$_.Name+' | MAC '+$_.MACAddress+' | Speed '+$_.Speed));}; $lines.Add(''); $lines.Add('--- IP CONFIGURATION ---'); $ip | ForEach-Object {$lines.Add(('IP                       : '+($_.IPAddress -join ', '))); $lines.Add(('GATEWAY                  : '+($_.DefaultIPGateway -join ', '))); $lines.Add(('DNS                      : '+($_.DNSServerSearchOrder -join ', ')));}; $lines.Add(''); $lines.Add('--- POWER SETTINGS ---'); $lines.Add('AC Monitor Timeout       : 3 minutes'); $lines.Add('AC Sleep Timeout         : 3 minutes'); $lines.Add('Battery Monitor Timeout : 3 minutes'); $lines.Add('Battery Sleep Timeout   : 3 minutes'); $lines.Add('Automatic Lock           : NO'); $lines.Add('Patch Installation      : NO'); $lines.Add(''); $lines.Add(('='*80)); $lines | Set-Content -LiteralPath $r -Encoding UTF8"

if errorlevel 1 (
    echo [WARNING] Inventory collection returned an error.
    >>"%LOG%" echo [WARNING] Inventory collection returned an error.
) else (
    echo [OK] System inventory saved.
    >>"%LOG%" echo [OK] System inventory saved: %REPORT%
)

>>"%LOG%" echo.
>>"%LOG%" echo Completed: %date% %time%

echo.
echo ============================================================
echo COMPLETED
 echo ============================================================
echo System report : %REPORT%
echo Cleanup log    : %LOG%
echo.
echo No patch detection or installation was performed.
echo No automatic workstation lock was performed.
echo ============================================================
echo.
pause
exit /b 0

:CleanFolder
set "TARGET=%~1"
set "LABEL=%~2"
echo [CLEAN] %LABEL%: %TARGET%
>>"%LOG%" echo [CLEAN] %LABEL%: %TARGET%
if not exist "%TARGET%" (
    echo [SKIP] Folder does not exist.
    >>"%LOG%" echo [SKIP] Folder does not exist.
    exit /b 0
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$p=$env:TARGET; $count=0; Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | ForEach-Object { try { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop; $count++ } catch {} }; Write-Output ('Removed items: '+$count)"
if errorlevel 1 (
    echo [WARNING] Some items could not be removed.
    >>"%LOG%" echo [WARNING] Some items could not be removed.
) else (
    echo [OK] Cleanup attempted. Locked/in-use items may remain.
    >>"%LOG%" echo [OK] Cleanup attempted. Locked/in-use items may remain.
)
exit /b 0

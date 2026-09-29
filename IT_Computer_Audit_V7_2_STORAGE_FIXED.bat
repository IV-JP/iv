@echo off
setlocal EnableExtensions EnableDelayedExpansion
title IT Computer Audit V7.0 - Hardware Inventory Menu

set "VERSION=7.0"
set "LOCAL_DIR=%USERPROFILE%\Desktop\IT"
set "NET_DIR=\\Iv-udp-lt-009\it"
set "FILE_NAME=%COMPUTERNAME%.txt"
set "LOCAL_PATH=%LOCAL_DIR%\%FILE_NAME%"
set "NET_PATH=%NET_DIR%\%FILE_NAME%"

if not exist "%LOCAL_DIR%" mkdir "%LOCAL_DIR%" >nul 2>&1

if /I not "%~1"=="RUNNING" (
    start "IT Computer Audit V7.0" cmd /k ""%~f0" RUNNING"
    exit /b
)

:MENU
cls
echo ==============================================================
echo              IT COMPUTER AUDIT V7.0
echo ==============================================================
echo Computer : %COMPUTERNAME%
echo User     : %USERNAME%
echo.
echo  [1] BASIC HARDWARE / ASSET INFORMATION
echo      CPU, Motherboard, RAM, SSD, HDD, Monitor,
echo      Keyboard, Mouse, GPU, BIOS, Computer Brand/Model
echo.
echo  [2] FULL COMPREHENSIVE COMPUTER AUDIT
echo      Hardware + Windows + Network + Security +
echo      Updates/Patches + Devices + Services + Power
echo.
echo  [3] EXIT
echo ==============================================================
set /p "CHOICE=Select option [1-3]: "

if "%CHOICE%"=="1" goto BASIC
if "%CHOICE%"=="2" goto FULL
if "%CHOICE%"=="3" goto END
echo.
echo Invalid option. Please select 1, 2 or 3.
timeout /t 2 /nobreak >nul
goto MENU

:BASIC
cls
echo ==============================================================
echo          BASIC HARDWARE / ASSET INFORMATION
echo ==============================================================
echo.
echo Report will be saved to:
echo %LOCAL_PATH%
echo.

> "%LOCAL_PATH%" echo ==============================================================
>>"%LOCAL_PATH%" echo          BASIC HARDWARE / ASSET INFORMATION
>>"%LOCAL_PATH%" echo ==============================================================
>>"%LOCAL_PATH%" echo Computer Name : %COMPUTERNAME%
>>"%LOCAL_PATH%" echo User          : %USERNAME%
>>"%LOCAL_PATH%" echo Domain        : %USERDOMAIN%
>>"%LOCAL_PATH%" echo Date          : %DATE%
>>"%LOCAL_PATH%" echo Time          : %TIME%
>>"%LOCAL_PATH%" echo Script        : %VERSION%
>>"%LOCAL_PATH%" echo ==============================================================
>>"%LOCAL_PATH%" echo.

echo [01/12] COMPUTER BRAND / MODEL / SERIAL...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [01] COMPUTER BRAND / MODEL / SERIAL
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $c=Get-CimInstance Win32_ComputerSystem; $p=Get-CimInstance Win32_ComputerSystemProduct; 'Manufacturer : '+$c.Manufacturer; 'Model        : '+$c.Model; 'System Family: '+$c.SystemFamily; 'Serial No    : '+$p.IdentifyingNumber; 'UUID         : '+$p.UUID; 'System Type  : '+$c.PCSystemType; 'User         : '+$c.UserName; 'Domain       : '+$c.Domain } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [01] COMPLETE

echo [02/12] CPU...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [02] CPU
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-CimInstance Win32_Processor | ForEach-Object { 'Brand         : '+$_.Manufacturer; 'Model         : '+$_.Name; 'Description   : '+$_.Description; 'CPU Serial/ID : '+$_.ProcessorId; 'Cores         : '+$_.NumberOfCores; 'Threads       : '+$_.NumberOfLogicalProcessors; 'Max MHz       : '+$_.MaxClockSpeed; 'Current MHz   : '+$_.CurrentClockSpeed; 'Socket        : '+$_.SocketDesignation; '----------------------------------------' } } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [02] COMPLETE

echo [03/12] MOTHERBOARD...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [03] MOTHERBOARD
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-CimInstance Win32_BaseBoard | ForEach-Object { 'Brand         : '+$_.Manufacturer; 'Model         : '+$_.Product; 'Version       : '+$_.Version; 'Serial No     : '+$_.SerialNumber; 'Asset Tag     : '+$_.Tag; '----------------------------------------' } } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [03] COMPLETE

echo [04/12] RAM...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [04] RAM
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $c=Get-CimInstance Win32_ComputerSystem; 'TOTAL RAM GB   : '+([math]::Round($c.TotalPhysicalMemory/1GB,2)); ''; Get-CimInstance Win32_PhysicalMemory | ForEach-Object { 'Brand           : '+$_.Manufacturer; 'Model/Part No   : '+$_.PartNumber; 'Serial No       : '+$_.SerialNumber; 'Capacity GB     : '+([math]::Round($_.Capacity/1GB,2)); 'Speed MHz       : '+$_.Speed; 'Configured MHz  : '+$_.ConfiguredClockSpeed; 'Slot            : '+$_.DeviceLocator; 'Bank            : '+$_.BankLabel; '----------------------------------------' } } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [04] COMPLETE

echo [05/12] SSD / HDD / NVMe...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [05] SSD / HDD / NVMe
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $d=Get-CimInstance Win32_DiskDrive; if($d){foreach($x in $d){ 'Disk Index     : '+$x.Index; 'Brand         : '+$x.Manufacturer; 'Model         : '+$x.Model; 'Serial No     : '+$x.SerialNumber; 'Media Type    : '+$x.MediaType; 'Interface     : '+$x.InterfaceType; 'Size GB       : '+([math]::Round($x.Size/1GB,2)); 'Firmware      : '+$x.FirmwareRevision; 'PNP ID        : '+$x.PNPDeviceID; '----------------------------------------' }}else{'NO PHYSICAL DISKS FOUND'} } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [05] COMPLETE

echo [06/12] MONITOR...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [06] MONITOR
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $m=Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction Stop; if($m){foreach($x in $m){$man='';$prod='';$ser='';if($x.ManufacturerName){$b=@($x.ManufacturerName | Where-Object {$_ -ne 0});if($b.Count -gt 0){$man=[Text.Encoding]::ASCII.GetString([byte[]]$b)}};if($x.UserFriendlyName){$b=@($x.UserFriendlyName | Where-Object {$_ -ne 0});if($b.Count -gt 0){$prod=[Text.Encoding]::ASCII.GetString([byte[]]$b)}};if($x.SerialNumberID){$b=@($x.SerialNumberID | Where-Object {$_ -ne 0});if($b.Count -gt 0){$ser=[Text.Encoding]::ASCII.GetString([byte[]]$b)}};'Brand         : '+$man;'Model         : '+$prod;'Serial No     : '+$ser;'----------------------------------------'}}else{'NO MONITOR EDID DATA'}} catch { 'Monitor EDID unavailable: '+$_.Exception.Message; try { Get-CimInstance Win32_DesktopMonitor | Select-Object Name,PNPDeviceID,Status | Format-List | Out-String -Width 240 } catch {} }" >>"%LOCAL_PATH%" 2>&1
echo [06] COMPLETE

echo [07/12] KEYBOARD...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [07] KEYBOARD
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-CimInstance Win32_Keyboard | ForEach-Object { 'Brand/Manufacturer: '+$_.Manufacturer; 'Model/Name       : '+$_.Name; 'Description      : '+$_.Description; 'Device ID        : '+$_.DeviceID; 'PNP ID            : '+$_.PNPDeviceID; 'Status            : '+$_.Status; 'Serial No        : Physical serial generally not exposed by Windows'; '----------------------------------------' } } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [07] COMPLETE

echo [08/12] MOUSE...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [08] MOUSE
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-CimInstance Win32_PointingDevice | ForEach-Object { 'Brand/Manufacturer: '+$_.Manufacturer; 'Model/Name       : '+$_.Name; 'Description      : '+$_.Description; 'Device ID        : '+$_.DeviceID; 'PNP ID            : '+$_.PNPDeviceID; 'Status            : '+$_.Status; 'Serial No        : Physical serial generally not exposed by Windows'; '----------------------------------------' } } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [08] COMPLETE

echo [09/12] GPU...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [09] GPU
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-CimInstance Win32_VideoController | ForEach-Object { $vram='N/A'; if($null -ne $_.AdapterRAM){$vram=[math]::Round($_.AdapterRAM/1GB,2)+' GB'}; 'Brand         : '+$_.AdapterCompatibility; 'Model         : '+$_.Name; 'Driver        : '+$_.DriverVersion; 'Driver Date   : '+$_.DriverDate; 'Video Memory  : '+$vram; 'PNP ID        : '+$_.PNPDeviceID; '----------------------------------------' } } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [09] COMPLETE

echo [10/12] BIOS...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [10] BIOS
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-CimInstance Win32_BIOS | ForEach-Object { 'Brand         : '+$_.Manufacturer; 'Model/Version : '+$_.SMBIOSBIOSVersion; 'Version       : '+$_.Version; 'Serial No     : '+$_.SerialNumber; 'Release Date  : '+$_.ReleaseDate } } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [10] COMPLETE

echo [11/12] NETWORK ADAPTER BASIC INFO...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [11] NETWORK ADAPTER BASIC INFO
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-NetAdapter | ForEach-Object { 'Adapter       : '+$_.Name; 'Brand         : '+$_.InterfaceDescription; 'MAC Address   : '+$_.MacAddress; 'Status        : '+$_.Status; 'Link Speed    : '+$_.LinkSpeed; '----------------------------------------' } } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [11] COMPLETE

echo [12/12] STORAGE VOLUMES...
>>"%LOCAL_PATH%" echo.
>>"%LOCAL_PATH%" echo [12] STORAGE VOLUMES
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-CimInstance Win32_LogicalDisk | ForEach-Object { $size='N/A'; $free='N/A'; if($null -ne $_.Size){$size=([math]::Round(([double]$_.Size / 1073741824),2)).ToString('0.00') + ' GB'}; if($null -ne $_.FreeSpace){$free=([math]::Round(([double]$_.FreeSpace / 1073741824),2)).ToString('0.00') + ' GB'}; 'Drive         : '+$_.DeviceID; 'Volume        : '+$_.VolumeName; 'File System   : '+$_.FileSystem; 'Size          : '+$size; 'Free Space    : '+$free; '----------------------------------------' } } catch { 'ERROR: '+$_.Exception.Message }" >>"%LOCAL_PATH%" 2>&1
echo [12] COMPLETE

goto COPY_REPORT

:FULL
cls
echo ==============================================================
echo          FULL COMPREHENSIVE COMPUTER AUDIT
echo ==============================================================
echo.
echo Running complete audit. No pause between sections.
echo.

> "%LOCAL_PATH%" echo ==============================================================
>>"%LOCAL_PATH%" echo          FULL COMPREHENSIVE COMPUTER AUDIT V7.0
>>"%LOCAL_PATH%" echo ==============================================================
>>"%LOCAL_PATH%" echo Computer Name : %COMPUTERNAME%
>>"%LOCAL_PATH%" echo User          : %USERNAME%
>>"%LOCAL_PATH%" echo Domain        : %USERDOMAIN%
>>"%LOCAL_PATH%" echo Date          : %DATE%
>>"%LOCAL_PATH%" echo Time          : %TIME%
>>"%LOCAL_PATH%" echo ==============================================================
>>"%LOCAL_PATH%" echo.

echo [01] DEVICE / SYSTEM...
>>"%LOCAL_PATH%" echo [01] DEVICE / SYSTEM
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_ComputerSystem | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [02] WINDOWS OS...
>>"%LOCAL_PATH%" echo [02] WINDOWS OS
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_OperatingSystem | Select-Object * | Format-List | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [03] WINDOWS BUILD / EDITION...
>>"%LOCAL_PATH%" echo [03] WINDOWS BUILD / EDITION
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Format-List ProductName,DisplayVersion,CurrentBuild,CurrentBuildNumber,UBR,EditionID,InstallationType,InstallDate | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [04] SYSTEM SERIAL / UUID...
>>"%LOCAL_PATH%" echo [04] SYSTEM SERIAL / UUID
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_ComputerSystemProduct | Format-List Vendor,Name,Version,IdentifyingNumber,UUID | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [05] BIOS...
>>"%LOCAL_PATH%" echo [05] BIOS
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_BIOS | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [06] MOTHERBOARD...
>>"%LOCAL_PATH%" echo [06] MOTHERBOARD
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_BaseBoard | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [07] CPU...
>>"%LOCAL_PATH%" echo [07] CPU
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Processor | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [08] RAM...
>>"%LOCAL_PATH%" echo [08] RAM
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_PhysicalMemory | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [09] SSD HDD NVMe...
>>"%LOCAL_PATH%" echo [09] SSD HDD NVMe
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_DiskDrive | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [10] LOGICAL STORAGE...
>>"%LOCAL_PATH%" echo [10] LOGICAL STORAGE
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_LogicalDisk | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [11] GPU...
>>"%LOCAL_PATH%" echo [11] GPU
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_VideoController | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [12] MONITOR...
>>"%LOCAL_PATH%" echo [12] MONITOR
powershell -NoProfile -ExecutionPolicy Bypass -Command "try {Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID | Format-List * | Out-String -Width 300}catch{'Monitor EDID unavailable: '+$_.Exception.Message}" >>"%LOCAL_PATH%" 2>&1

echo [13] KEYBOARD...
>>"%LOCAL_PATH%" echo [13] KEYBOARD
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Keyboard | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [14] MOUSE...
>>"%LOCAL_PATH%" echo [14] MOUSE
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_PointingDevice | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [15] USB DEVICES...
>>"%LOCAL_PATH%" echo [15] USB DEVICES
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PnpDevice -PresentOnly | Where-Object {$_.Class -eq 'USB' -or $_.InstanceId -like 'USB*'} | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [16] CAMERA...
>>"%LOCAL_PATH%" echo [16] CAMERA
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PnpDevice -PresentOnly | Where-Object {$_.Class -eq 'Camera' -or $_.FriendlyName -match 'camera|webcam'} | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [17] AUDIO...
>>"%LOCAL_PATH%" echo [17] AUDIO
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_SoundDevice | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [18] NETWORK ADAPTERS...
>>"%LOCAL_PATH%" echo [18] NETWORK ADAPTERS
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [19] IP CONFIGURATION...
>>"%LOCAL_PATH%" echo [19] IP CONFIGURATION
ipconfig /all >>"%LOCAL_PATH%" 2>&1

echo [20] BLUETOOTH...
>>"%LOCAL_PATH%" echo [20] BLUETOOTH
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PnpDevice -PresentOnly | Where-Object {$_.Class -eq 'Bluetooth'} | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [21] PRINTERS...
>>"%LOCAL_PATH%" echo [21] PRINTERS
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Printer | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [22] BATTERY...
>>"%LOCAL_PATH%" echo [22] BATTERY
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b=Get-CimInstance Win32_Battery;if($b){$b|Format-List *|Out-String -Width 300}else{'NO BATTERY / DESKTOP'}" >>"%LOCAL_PATH%" 2>&1

echo [23] PNP HARDWARE...
>>"%LOCAL_PATH%" echo [23] PNP HARDWARE
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PnpDevice -PresentOnly | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [24] DEVICE ERRORS...
>>"%LOCAL_PATH%" echo [24] DEVICE ERRORS
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=Get-PnpDevice|Where-Object {$_.Status -ne 'OK'};if($d){$d|Format-List *|Out-String -Width 300}else{'NO NON-OK PNP DEVICES'}" >>"%LOCAL_PATH%" 2>&1

echo [25] WINDOWS DEFENDER...
>>"%LOCAL_PATH%" echo [25] WINDOWS DEFENDER
powershell -NoProfile -ExecutionPolicy Bypass -Command "try{Get-MpComputerStatus|Format-List *|Out-String -Width 300}catch{'DEFENDER STATUS UNAVAILABLE: '+$_.Exception.Message}" >>"%LOCAL_PATH%" 2>&1

echo [26] FIREWALL...
>>"%LOCAL_PATH%" echo [26] FIREWALL
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetFirewallProfile | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [27] WINDOWS UPDATE SERVICE...
>>"%LOCAL_PATH%" echo [27] WINDOWS UPDATE SERVICE
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Service wuauserv | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [28] BITS...
>>"%LOCAL_PATH%" echo [28] BITS
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Service BITS | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [29] UPDATE SERVICES...
>>"%LOCAL_PATH%" echo [29] UPDATE SERVICES
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Service usosvc,WaaSMedicSvc,DoSvc -ErrorAction SilentlyContinue | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [30] INSTALLED HOTFIXES / KB...
>>"%LOCAL_PATH%" echo [30] INSTALLED HOTFIXES / KB
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-HotFix | Sort-Object InstalledOn -Descending | Format-Table -AutoSize | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [31] PENDING WINDOWS UPDATES...
>>"%LOCAL_PATH%" echo [31] PENDING WINDOWS UPDATES
powershell -NoProfile -ExecutionPolicy Bypass -Command "try{$s=New-Object -ComObject Microsoft.Update.Session;$q=$s.CreateUpdateSearcher();$r=$q.Search('IsInstalled=0 and IsHidden=0');'Pending update count: '+$r.Updates.Count;for($i=0;$i -lt $r.Updates.Count;$i++){$u=$r.Updates.Item($i);'TITLE: '+$u.Title;'KB: '+($u.KBArticleIDs -join ', ');'SEVERITY: '+$u.MsrcSeverity;'---'}}catch{'UPDATE SEARCH UNAVAILABLE: '+$_.Exception.Message}" >>"%LOCAL_PATH%" 2>&1

echo [32] WINDOWS UPDATE POLICY...
>>"%LOCAL_PATH%" echo [32] WINDOWS UPDATE POLICY
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -ErrorAction SilentlyContinue | Format-List * | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [33] LAST BOOT / UPTIME...
>>"%LOCAL_PATH%" echo [33] LAST BOOT / UPTIME
powershell -NoProfile -ExecutionPolicy Bypass -Command "$o=Get-CimInstance Win32_OperatingSystem;'Last Boot: '+$o.LastBootUpTime;'Current: '+(Get-Date);'Uptime: '+((Get-Date)-$o.LastBootUpTime)" >>"%LOCAL_PATH%" 2>&1

echo [34] SECURITY SERVICES...
>>"%LOCAL_PATH%" echo [34] SECURITY SERVICES
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Service BITS,wuauserv,mpssvc,WinDefend,SecurityHealthService,EventLog -ErrorAction SilentlyContinue | Format-Table -AutoSize | Out-String -Width 300" >>"%LOCAL_PATH%" 2>&1

echo [35] POWER SCHEME...
>>"%LOCAL_PATH%" echo [35] POWER SCHEME
powercfg /getactivescheme >>"%LOCAL_PATH%" 2>&1

echo [36] SYSTEMINFO...
>>"%LOCAL_PATH%" echo [36] SYSTEMINFO
systeminfo >>"%LOCAL_PATH%" 2>&1

echo [37] POWER SETTINGS...
>>"%LOCAL_PATH%" echo [37] POWER SETTINGS
powercfg /query SCHEME_CURRENT SUB_VIDEO >>"%LOCAL_PATH%" 2>&1
powercfg /query SCHEME_CURRENT SUB_SLEEP >>"%LOCAL_PATH%" 2>&1

echo [38] ENVIRONMENT / USER...
>>"%LOCAL_PATH%" echo [38] ENVIRONMENT / USER
set >>"%LOCAL_PATH%" 2>&1

echo [39] DISK SPACE...
>>"%LOCAL_PATH%" echo [39] DISK SPACE
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{N='UsedGB';E={[math]::Round($_.Used/1GB,2)}},@{N='FreeGB';E={[math]::Round($_.Free/1GB,2)}} | Format-Table -AutoSize | Out-String -Width 240" >>"%LOCAL_PATH%" 2>&1

echo [40] FINAL...
>>"%LOCAL_PATH%" echo [40] FINAL
>>"%LOCAL_PATH%" echo Audit completed: %DATE% %TIME%

goto COPY_REPORT

:COPY_REPORT
echo.
echo ==============================================================
echo REPORT CREATED
echo ==============================================================
echo Local: %LOCAL_PATH%
echo.

if exist "%NET_DIR%\." (
    echo Copying report to network...
    copy /Y "%LOCAL_PATH%" "%NET_PATH%" >nul 2>&1
    if errorlevel 1 (
        echo First network copy failed. Retrying...
        timeout /t 5 /nobreak >nul
        copy /Y "%LOCAL_PATH%" "%NET_PATH%" >nul 2>&1
    )
    if errorlevel 1 (
        echo [WARNING] Network copy failed.
        echo [OK] Local report retained.
    ) else (
        echo [OK] Network report copied successfully.
    )
) else (
    echo [WARNING] Network share unavailable.
    echo [OK] Local report retained.
)

echo.
echo ==============================================================
echo AUDIT COMPLETE
echo ==============================================================
echo Local report : %LOCAL_PATH%
echo Network      : %NET_PATH%
echo.
echo Press M to return to menu or X to close.
choice /c MX /n /m "Select [M/X]: "
if errorlevel 2 goto END
goto MENU

:END
echo.
echo Window will remain open.
echo You can close it manually.
cmd /k
exit /b

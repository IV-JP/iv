@echo off
setlocal EnableExtensions EnableDelayedExpansion
title STRONG SYSTEM CLEANUP - FINAL
color 0A

set "LOG=%SystemDrive%\SystemCleanup_30Days.log"

echo ============================================================
echo        STRONG WINDOWS SYSTEM CLEANUP
echo        LOW DISK + 30 DAY OLD USER PROFILES
echo ============================================================
echo.
echo Started: %date% %time%
echo Log: %LOG%
echo.

:: ADMIN CHECK
echo [CHECK 1] Administrator permission...
net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Run this BAT as Administrator.
    echo Right-click ^> Run as administrator.
    echo.
    pause
    exit /b 1
)
echo [OK] Administrator confirmed.
echo.

:: GET BEFORE SPACE - NO POWERSHELL VARIABLE/PATH NESTING
echo [CHECK 2] Checking C: drive...
for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "(Get-PSDrive C).Free"') do set "BEFORE_BYTES=%%A"
if not defined BEFORE_BYTES (
    echo [ERROR] Could not read C: free space.
    pause
    exit /b 1
)

for /f %%A in ('powershell.exe -NoProfile -Command "[math]::Round(%BEFORE_BYTES%/1GB,2)"') do set "BEFORE_GB=%%A"
for /f %%A in ('powershell.exe -NoProfile -Command "$d=Get-PSDrive C; [math]::Round(($d.Free/($d.Free+$d.Used))*100,1)"') do set "BEFORE_PCT=%%A"

echo C: Free before cleanup: %BEFORE_GB% GB
echo C: Free percentage: %BEFORE_PCT%%
echo.

echo [%date% %time%] CLEANUP STARTED > "%LOG%"
echo BEFORE FREE: %BEFORE_GB% GB >> "%LOG%"

:: 1 WINDOWS TEMP
echo ============================================================
echo [1/8] WINDOWS TEMP
echo ============================================================
call :CleanFolder "%windir%\Temp"

:: 2 USER TEMP/CACHE
echo.
echo ============================================================
echo [2/8] USER TEMP AND SAFE CACHE
echo ============================================================
for /d %%U in ("%SystemDrive%\Users\*") do (
    echo.
    echo User: %%~nxU
    if exist "%%~fU\AppData\Local\Temp" call :CleanFolder "%%~fU\AppData\Local\Temp"
    if exist "%%~fU\AppData\Local\Microsoft\Windows\INetCache" call :CleanFolder "%%~fU\AppData\Local\Microsoft\Windows\INetCache"
    if exist "%%~fU\AppData\Local\CrashDumps" call :CleanFolder "%%~fU\AppData\Local\CrashDumps"
    if exist "%%~fU\AppData\Local\D3DSCache" call :CleanFolder "%%~fU\AppData\Local\D3DSCache"
)

:: 3 WINDOWS UPDATE
echo.
echo ============================================================
echo [3/8] WINDOWS UPDATE DOWNLOAD CACHE
echo ============================================================
call :CleanFolder "%windir%\SoftwareDistribution\Download"

:: 4 DELIVERY OPTIMIZATION
echo.
echo ============================================================
echo [4/8] DELIVERY OPTIMIZATION CACHE
echo ============================================================
call :CleanFolder "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache"

:: 5 RECYCLE BIN
echo.
echo ============================================================
echo [5/8] RECYCLE BIN
echo ============================================================
powershell.exe -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo [OK] Recycle Bin cleanup completed.

:: 6 DISK CLEANUP
echo.
echo ============================================================
echo [6/8] WINDOWS DISK CLEANUP
echo ============================================================
if exist "%SystemRoot%\System32\cleanmgr.exe" (
    cleanmgr.exe /verylowdisk
    echo Disk Cleanup exit code: %errorlevel%
) else (
    echo [WARNING] cleanmgr.exe not found.
)

:: 7 OLD PROFILES
echo.
echo ============================================================
echo [7/8] USER PROFILES INACTIVE FOR 30+ DAYS
echo ============================================================
echo.
echo The report below is based on the profile folder last-write date.
echo Current, loaded, system and protected profiles are excluded.
echo.
echo If profiles are found, you will be asked to type YES.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$cutoff=(Get-Date).AddDays(-30); $current=$env:USERNAME; $protected=@('Administrator','Default','Default User','Public','All Users','defaultuser0','WDAGUtilityAccount'); $items=@(); Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special -and $_.LocalPath -like 'C:\Users\*' } | ForEach-Object { $name=Split-Path $_.LocalPath -Leaf; if($name -in $protected -or $name -eq $current -or $_.Loaded){return}; try{$dt=(Get-Item -LiteralPath $_.LocalPath -Force).LastWriteTime}catch{return}; if($dt -lt $cutoff){$size=0; try{$size=(Get-ChildItem -LiteralPath $_.LocalPath -Force -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum}catch{}; $items += [PSCustomObject]@{Name=$name;SizeGB=[math]::Round($size/1GB,2);LastUsed=$dt;Path=$_.LocalPath;SID=$_.SID}}}; if($items.Count -eq 0){Write-Host 'No inactive profiles older than 30 days found.'; exit}; $items | Sort-Object SizeGB -Descending | Format-Table Name,SizeGB,LastUsed,Path -AutoSize; Write-Host ''; $answer=Read-Host 'Delete ALL profiles shown above? Type YES'; if($answer -ne 'YES'){Write-Host 'Profile deletion cancelled.'; exit}; foreach($i in $items){try{$p=Get-CimInstance Win32_UserProfile | Where-Object SID -eq $i.SID; if($p -and -not $p.Loaded){$p | Remove-CimInstance -ErrorAction Stop; Write-Host ('DELETED: '+$i.Name+' ('+$i.SizeGB+' GB)'); Add-Content -LiteralPath '%LOG%' -Value ('DELETED PROFILE: '+$i.Name+' | '+$i.SizeGB+' GB | '+$i.Path)}}catch{Write-Host ('FAILED: '+$i.Name+' - '+$_.Exception.Message); Add-Content -LiteralPath '%LOG%' -Value ('FAILED PROFILE: '+$i.Name+' | '+$_.Exception.Message)}}"

:: 8 DISM - LAST CLEANUP STEP
echo.
echo ============================================================
echo [8/8] WINDOWS COMPONENT STORE - DISM CLEANUP
echo ============================================================
echo DISM is the final cleanup step.
echo DISM can take several minutes. Do not close the window.
DISM.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart
echo DISM exit code: %errorlevel%

:: FINAL SPACE
echo.
echo ============================================================
echo FINAL DISK SPACE REPORT
echo ============================================================

for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "(Get-PSDrive C).Free"') do set "AFTER_BYTES=%%A"

if not defined AFTER_BYTES (
    echo [ERROR] Could not read final C: space.
    goto END
)

for /f %%A in ('powershell.exe -NoProfile -Command "[math]::Round(%AFTER_BYTES%/1GB,2)"') do set "AFTER_GB=%%A"
for /f %%A in ('powershell.exe -NoProfile -Command "$d=Get-PSDrive C; [math]::Round(($d.Free/($d.Free+$d.Used))*100,1)"') do set "AFTER_PCT=%%A"
for /f %%A in ('powershell.exe -NoProfile -Command "[math]::Round((%AFTER_BYTES%-%BEFORE_BYTES%)/1GB,2)"') do set "GAIN_GB=%%A"

:: If BEFORE_BYTES was not captured correctly, calculate gain from GB instead.
if not defined GAIN_GB set "GAIN_GB=N/A"

echo.
echo BEFORE : %BEFORE_GB% GB free
echo AFTER  : %AFTER_GB% GB free
echo GAIN   : %GAIN_GB% GB
echo FREE   : %AFTER_PCT%%
echo.

echo FINAL FREE: %AFTER_GB% GB >> "%LOG%"
echo RECOVERED: %GAIN_GB% GB >> "%LOG%"
echo FINAL FREE PERCENT: %AFTER_PCT%%% >> "%LOG%"
echo [%date% %time%] CLEANUP COMPLETED >> "%LOG%"

:END
echo ============================================================
echo CLEANUP COMPLETED
echo ============================================================
echo.
echo Log:
echo %LOG%
echo.
echo This window will remain open.
pause
exit /b 0

:CleanFolder
set "TARGET=%~1"
if not exist "%TARGET%" (
    echo [SKIP] %TARGET%
    exit /b 0
)
echo Cleaning: %TARGET%
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$p='%TARGET%'; Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue"
echo [OK] %TARGET%
exit /b 0

@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:MENU
cls
echo ============================================
echo        USB & Website Control Menu
echo ============================================
echo.
echo  1. Block USB and Restricted Sites (YouTube, Hotstar, Movies, Games)
echo  2. Unblock USB and Restore All Websites
echo  3. Exit
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" goto BLOCK
if "%choice%"=="2" goto UNBLOCK
if "%choice%"=="3" exit
goto MENU

:BLOCK
echo.
echo [1/2] Disabling USB storage devices...
reg add HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR /v Start /t REG_DWORD /d 4 /f

echo [2/2] Adding domain block rules to Hosts file...

:: YouTube
echo 127.0.0.1 youtube.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 www.youtube.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 youtu.be >> %windir%\System32\drivers\etc\hosts

:: Disney+ Hotstar
echo 127.0.0.1 hotstar.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 www.hotstar.com >> %windir%\System32\drivers\etc\hosts

:: Movie / Streaming
echo 127.0.0.1 netflix.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 www.netflix.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 primevideo.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 zee5.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 sonyliv.com >> %windir%\System32\drivers\etc\hosts

:: Gaming Sites
echo 127.0.0.1 steampowered.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 store.steampowered.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 epicgames.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 roblox.com >> %windir%\System32\drivers\etc\hosts
echo 127.0.0.1 www.roblox.com >> %windir%\System32\drivers\etc\hosts

ipconfig /flushdns
echo.
echo Blocking completed successfully!
pauses
goto MENU

:UNBLOCK
echo.
echo [1/2] Unblocking USB storage devices...
reg add HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR /v Start /t REG_DWORD /d 3 /f

echo [2/2] Restoring default Windows Hosts file...
(
    echo # Copyright (c) 1993-2006 Microsoft Corp.
    echo #
    echo # This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
    echo #
    echo # This file contains the mappings of IP addresses to host names. Each
    echo # entry should be kept on an individual line. The IP address should
    echo # be placed in the first column followed by the corresponding host name.
    echo # The IP address and the host name should be separated by at least one
    echo # space.
    echo #
    echo # Additionally, comments (such as these) may be inserted on individual
    echo # lines or following the machine name for individual computers denoted
    echo # with a # symbol.
    echo #
    echo # For example:
    echo #
    echo #      127.0.0.1 localhost
    echo #      ::1       localhost
    echo 127.0.0.1 localhost
    echo ::1       localhost
) > %windir%\System32\drivers\etc\hosts

ipconfig /flushdns
echo.
echo Unblocking completed successfully!
pause
goto MENU
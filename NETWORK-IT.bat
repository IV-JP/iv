@echo off
setlocal EnableDelayedExpansion
title Network Configuration & Status Utility
color 0B

:CHOOSE_ADAPTER
cls
echo ========================================================
echo   Network Adapter Detection & Selection
echo ========================================================
echo.
echo Checking current interface status:
echo --------------------------------------------------------
netsh interface show interface
echo --------------------------------------------------------
echo.
echo Select the network interface to configure:
echo 1. Ethernet
echo 2. Wi-Fi
echo 3. Enter Custom Adapter Name
echo 4. Exit
echo.
set /p adapter_choice="Select an option (1-4): "

if "%adapter_choice%"=="1" set "ADAPTER=Ethernet" & goto CHECK_CONN
if "%adapter_choice%"=="2" set "ADAPTER=Wi-Fi" & goto CHECK_CONN
if "%adapter_choice%"=="3" goto CUSTOM_ADAPTER
if "%adapter_choice%"=="4" exit
goto CHOOSE_ADAPTER

:CUSTOM_ADAPTER
echo.
set /p "ADAPTER=Enter exact Adapter Name: "
if "%ADAPTER%"=="" goto CHOOSE_ADAPTER

:CHECK_CONN
echo.
echo Checking connection status for "%ADAPTER%"...

:: Check if the selected adapter is in "Connected" state
netsh interface show interface name="%ADAPTER%" | findstr /I "Connected" >nul
if errorlevel 1 (
    echo.
    echo [WARNING] "%ADAPTER%" is currently DISCONNECTED or not found!
    echo Please plug in your cable or connect to Wi-Fi.
    echo.
    set /p retry_choice="Do you still want to proceed anyway? (Y/N): "
    if /I not "!retry_choice!"=="Y" goto CHOOSE_ADAPTER
) else (
    echo [OK] "%ADAPTER%" is CONNECTED.
)
pause

:MENU
cls
echo ========================================================
echo   Configuring: [%ADAPTER%]
echo ========================================================
echo 1. Auto-Find and Assign Static IP Configuration
echo 2. Switch Interface to DHCP
echo 3. Release and Renew DHCP Lease
echo 4. Switch / Change Network Adapter
echo 5. Exit
echo ========================================================
echo.
set /p choice="Select an operation (1-5): "

if "%choice%"=="1" goto STATIC
if "%choice%"=="2" goto DHCP
if "%choice%"=="3" goto RENEW
if "%choice%"=="4" goto CHOOSE_ADAPTER
if "%choice%"=="5" exit
goto MENU

:STATIC
cls
echo ========================================================
echo   AUTO-DISCOVERY ^& STATIC IP ASSIGNMENT
echo ========================================================
echo Scanning 192.168.0.1 - 254 for available IPs...
echo Please wait while we find the first 10 options...
echo ========================================================
echo.

set count=0

:: Loop through the entire 1-254 range
for /L %%i in (1,1,254) do (
    :: Ping the IP and look specifically for "TTL=" to avoid false positives
    ping -n 1 -w 50 192.168.0.%%i | find "TTL=" >nul
    
    :: If "TTL=" is NOT found, the ping failed (IP might be available)
    if errorlevel 1 (
        :: Check ARP table with exact spacing to prevent .1 matching .10
        arp -a | findstr /c:"  192.168.0.%%i  " >nul
        if errorlevel 1 (
            set /a count+=1
            set "avail_ip[!count!]=192.168.0.%%i"
            echo [!count!] 192.168.0.%%i
            
            :: Stop scanning once we hit 10 IPs
            if !count! EQU 10 goto SELECT_IP
        )
    )
)

:: If the loop finishes and finds nothing:
if !count! EQU 0 (
    echo [ERROR] No available IP addresses found in this range!
    pause
    goto MENU
)

:SELECT_IP
echo.
echo ========================================================
echo Enter the bracketed number [1-!count!] to select an IP from the list.
echo OR, enter a custom last octet manually (e.g., type 50 for 192.168.0.50).
set /p "ip_choice=Choice: "

if "!ip_choice!"=="" goto SELECT_IP

:: Check if the user entered a bracketed list number or a custom last octet
if defined avail_ip[%ip_choice%] (
    set "NEW_IP=!avail_ip[%ip_choice%]!"
) else (
    set "NEW_IP=192.168.0.!ip_choice!"
)

goto APPLY_STATIC

:APPLY_STATIC
echo.
echo [1/3] Applying Static IP (%NEW_IP%), Subnet, and Gateway to "%ADAPTER%"...
netsh interface ipv4 set address name="%ADAPTER%" static %NEW_IP% 255.255.255.0 192.168.0.100

echo [2/3] Setting Primary DNS (Position 1)...
netsh interface ipv4 set dnsservers name="%ADAPTER%" static 172.16.2.152 primary validate=no

echo [3/3] Appending additional DNS Servers to Advanced TCP/IP Settings...
netsh interface ipv4 add dnsserver name="%ADAPTER%" 8.8.8.8 index=2 validate=no
netsh interface ipv4 add dnsserver name="%ADAPTER%" 172.16.3.158 index=3 validate=no
netsh interface ipv4 add dnsserver name="%ADAPTER%" 96.45.45.45 index=4 validate=no

echo.
echo Static configuration (%NEW_IP%) applied successfully to "%ADAPTER%"!
pause
goto MENU

:DHCP
echo.
echo [1/2] Setting IP address assignment to DHCP on "%ADAPTER%"...
netsh interface ipv4 set address name="%ADAPTER%" source=dhcp

echo [2/2] Setting DNS server assignment to DHCP on "%ADAPTER%"...
netsh interface ipv4 set dnsservers name="%ADAPTER%" source=dhcp

echo.
echo "%ADAPTER%" successfully reverted to DHCP!
pause
goto MENU

:RENEW
echo.
echo [1/2] Releasing current DHCP lease...
ipconfig /release >nul

echo [2/2] Requesting new lease from DHCP server...
ipconfig /renew

echo.
echo IP lease successfully renewed!
pause
goto MENU
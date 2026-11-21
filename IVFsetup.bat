@echo off
title System Setup Tool

:: This ensures winget and powershell work perfectly in Admin mode
set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WindowsApps;%USERPROFILE%\AppData\Local\Microsoft\WindowsApps;%SystemRoot%\System32\WindowsPowerShell\v1.0\"

:MAIN_MENU
cls
echo =========================================
echo    System Setup Menu
echo =========================================
echo [1] Create New Local User Account
echo [2] Install Machine-Wide Software ^& Icons
echo [3] Exit
echo =========================================
set /p CHOICE="Select an option (1, 2, or 3) and press Enter: "

if "%CHOICE%"=="1" goto CREATE_USER
if "%CHOICE%"=="2" goto INSTALL_SOFTWARE
if "%CHOICE%"=="3" goto END

:: If the user types something else, reload the menu
goto MAIN_MENU


:CREATE_USER
cls
echo =========================================
echo    Option 1: Local User Creation
echo =========================================
echo You are creating a new user ID with the format: IVF-RCR-LT-[Your-Numbers]
echo.
set /p USER_SERIAL="Enter the ID numbers for this PC (e.g., 21-33): "
set "NEW_USER=IVF-RCR-LT-%USER_SERIAL%"

echo.
echo Creating user account: %NEW_USER%...
net user "%NEW_USER%" "Indi123&" /add

echo.
echo User %NEW_USER% has been created successfully!
echo.
pause
goto MAIN_MENU


:INSTALL_SOFTWARE
cls
echo =========================================
echo    Option 2: Installing Machine-Wide Apps
echo =========================================

echo.
echo [1/8] Installing Google Chrome...
winget install --id Google.Chrome -e --source winget --scope machine --accept-source-agreements --accept-package-agreements

echo.
echo [2/8] Installing Mozilla Firefox...
winget install --id Mozilla.Firefox -e --source winget --scope machine --accept-source-agreements --accept-package-agreements

echo.
echo [3/8] Installing Java JDK 21...
winget install --id Oracle.JDK.21 -e --source winget --scope machine --accept-source-agreements --accept-package-agreements

echo.
echo [4/8] Installing Python 3.12...
winget install --id Python.Python.3.12 -e --source winget --scope machine --accept-source-agreements --accept-package-agreements

echo.
echo [5/8] Installing Scratch Desktop...
winget install --id MITMediaLab.Scratch.3 -e --source winget --scope machine --accept-source-agreements --accept-package-agreements


echo.
echo [7/8] Installing AnyDesk (via Direct Download)...
powershell -Command "Invoke-WebRequest -Uri 'https://download.anydesk.com/AnyDesk.exe' -OutFile '%TEMP%\AnyDesk.exe'; Start-Process -FilePath '%TEMP%\AnyDesk.exe' -ArgumentList '--install','%ProgramFiles(x86)%\AnyDesk','--start-with-win','--create-shortcuts','--create-desktop-icon','--silent' -Wait"

echo.
echo [8/8] Installing UltraViewer...
winget install --id DucFabulous.UltraViewer -e --source winget --scope machine --accept-source-agreements --accept-package-agreements

echo.
echo [6/8] Installing Visual Studio Code (System Installer via Direct Download)...
powershell -Command "Invoke-WebRequest -Uri 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64' -OutFile '%TEMP%\vscode_installer.exe'; Start-Process -FilePath '%TEMP%\vscode_installer.exe' -ArgumentList '/verysilent' -Wait; Remove-Item '%TEMP%\vscode_installer.exe'"


echo.
echo =========================================
echo    Generating Public Desktop Shortcuts
echo =========================================
:: We build a temporary PowerShell script to safely generate icons for ALL users
echo $wshell = New-Object -ComObject WScript.Shell > "%TEMP%\create_icons.ps1"
echo $Desktop = 'C:\Users\Public\Desktop' >> "%TEMP%\create_icons.ps1"
echo function Make-Icon($path, $name) { if(Test-Path $path) { $s = $wshell.CreateShortcut("$Desktop\$name.lnk"); $s.TargetPath = $path; $s.Save(); } } >> "%TEMP%\create_icons.ps1"

:: Chrome and Firefox
echo Make-Icon 'C:\Program Files\Google\Chrome\Application\chrome.exe' 'Google Chrome' >> "%TEMP%\create_icons.ps1"
echo Make-Icon 'C:\Program Files\Mozilla Firefox\firefox.exe' 'Firefox' >> "%TEMP%\create_icons.ps1"

:: Scratch Desktop
echo Make-Icon 'C:\Program Files\Scratch 3\Scratch 3.exe' 'Scratch Desktop' >> "%TEMP%\create_icons.ps1"
echo Make-Icon 'C:\Program Files (x86)\Scratch Desktop\Scratch Desktop.exe' 'Scratch Desktop' >> "%TEMP%\create_icons.ps1"

:: Visual Studio Code
echo Make-Icon 'C:\Program Files\Microsoft VS Code\Code.exe' 'Visual Studio Code' >> "%TEMP%\create_icons.ps1"

:: AnyDesk and UltraViewer
echo Make-Icon 'C:\Program Files (x86)\AnyDesk\AnyDesk.exe' 'AnyDesk' >> "%TEMP%\create_icons.ps1"
echo Make-Icon 'C:\Program Files (x86)\UltraViewer\UltraViewer_Desktop.exe' 'UltraViewer' >> "%TEMP%\create_icons.ps1"

:: Python IDLE
echo Make-Icon 'C:\Program Files\Python312\Lib\idlelib\idle.bat' 'Python IDLE' >> "%TEMP%\create_icons.ps1"

powershell -ExecutionPolicy Bypass -File "%TEMP%\create_icons.ps1"
del "%TEMP%\create_icons.ps1"

echo.
echo Desktop icons have been successfully created on the Public Desktop!
echo.
pause
goto MAIN_MENU


:END
exit
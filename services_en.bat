@echo off
chcp 65001 >nul 2>&1
title RDP and Remote Connection Services Checker
color 0A

:: ============================================================
::  SCRIPT: Enable Remote Desktop (RDP) Services
::  USAGE:  Run as Administrator
::  ORDER:
::    1. Enable and start all services
::    2. Turn on Remote Desktop (toggle On in Settings)
::    3. Show computer IPv4 address
:: ============================================================

:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [ERROR] This script must be run as Administrator.
    echo  Right-click the file and select
    echo  "Run as administrator".
    echo.
    pause
    exit /b 1
)

echo.
echo  ============================================================
echo   RDP / Remote Connection Services Enabler - Windows
echo  ============================================================
echo.
echo  Computer: %COMPUTERNAME%
echo  Date:     %date%  Time: %time%
echo.

:: ============================================================
::  PHASE 1: ENABLE AND START SERVICES
:: ============================================================

echo  ============================================================
echo   PHASE 1: Enabling and starting services...
echo  ============================================================

call :process_service "RasAuto"        "Remote Access Auto Connection Manager"
call :process_service "RasMan"         "Remote Access Connection Manager"
call :process_service "SessionEnv"     "Remote Desktop Configuration"
call :process_service "TermService"    "Remote Desktop Services"
call :process_service "UmRdpService"   "Remote Desktop Services UserMode Port Redirector"
call :process_service "RpcSs"          "Remote Procedure Call (RPC)"
call :process_service "RpcLocator"     "Remote Procedure Call (RPC) Locator"
call :process_service "RemoteRegistry" "Remote Registry"
call :process_service "RetailDemo"     "Retail Demo Service"
call :process_service "RemoteAccess"   "Routing and Remote Access"

echo.
echo  ------------------------------------------------------------
echo   All services have been processed.
echo  ------------------------------------------------------------

:: ============================================================
::  PHASE 2: TURN ON REMOTE DESKTOP (Toggle ON)
::  This is equivalent to turning on the switch in:
::  Settings ^> System ^> Remote Desktop
:: ============================================================

echo.
echo  ============================================================
echo   PHASE 2: Turning on Remote Desktop in Windows...
echo  ============================================================

echo.
echo  [CONFIG] Enabling Remote Desktop (fDenyTSConnections = 0)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Remote Desktop ENABLED (toggle ON).
) else (
    echo    [ERROR] Could not enable Remote Desktop.
)

:: ============================================================
::  PHASE 3: SHOW COMPUTER IPv4 ADDRESS
:: ============================================================

echo.
echo  ============================================================
echo   PHASE 3: Connection information
echo  ============================================================
echo.
echo  [INFO] IPv4 address(es) detected on this computer:
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    echo    ****  %%a
)
echo.
echo  ------------------------------------------------------------
echo.
echo  SUMMARY:
echo    - Services:         10 processed
echo    - Remote Desktop:   ENABLED (ON)
echo    - Computer:         %COMPUTERNAME%
echo.
echo  To connect use:
echo    mstsc /v:[IPv4 above]
echo.
echo  ============================================================
echo  Process completed successfully.
echo  ============================================================
echo.
pause
exit /b 0

:: ============================================================
::  FUNCTION: process_service
:: ============================================================
:process_service
set "SERVICE_NAME=%~1"
set "DESCRIPTION=%~2"

echo.
echo  [INFO] Processing: %DESCRIPTION% (%SERVICE_NAME%)

:: Check if the service exists
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo    [WARNING] Service "%SERVICE_NAME%" does not exist on this computer. Skipping...
    goto :eof
)

:: --- Step 1: Check and configure startup type ---
sc qc "%SERVICE_NAME%" 2>nul | findstr /i "AUTO_START" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Startup type: Automatic
) else (
    echo    [CHANGE] Setting startup type to Automatic...
    sc config "%SERVICE_NAME%" start= auto >nul 2>&1
    if %errorlevel% equ 0 (
        echo    [OK] Startup type changed to Automatic.
    ) else (
        echo    [ERROR] Could not change startup type.
    )
)

:: --- Step 2: Check and start the service ---
sc query "%SERVICE_NAME%" 2>nul | findstr /i "RUNNING" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Status: Running
) else (
    echo    [CHANGE] Starting service...
    sc start "%SERVICE_NAME%" >nul 2>&1
    timeout /t 3 /nobreak >nul 2>&1
    sc query "%SERVICE_NAME%" 2>nul | findstr /i "RUNNING" >nul 2>&1
    if %errorlevel% equ 0 (
        echo    [OK] Service started successfully.
    ) else (
        echo    [WARNING] Service did not reach RUNNING state.
        echo              It may need more time or depend on another service.
    )
)

goto :eof
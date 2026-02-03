@echo off
chcp 65001 >nul 2>&1
title Verificador de Servicios RDP y Conexion Remota

:: ============================================================
::  SCRIPT: Habilitar servicios de Escritorio Remoto (RDP)
::  USO:    Ejecutar como Administrador
::  ORDEN:
::    1. Habilitar e iniciar todos los servicios
::    2. Activar Escritorio Remoto (toggle On en Configuracion)
::    3. Mostrar IPv4 del equipo
:: ============================================================

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [ERROR] Este script debe ejecutarse como Administrador.
    echo  Haz clic derecho sobre el archivo y selecciona
    echo  "Ejecutar como administrador".
    echo.
    pause
    exit /b 1
)

echo.
echo  ============================================================
echo                Habilitador de Servicios RDP
echo  ============================================================
echo.
echo  Equipo: %COMPUTERNAME%
echo  Fecha:  %date%  Hora: %time%
echo  ============================================================
echo.

call :procesar_servicio "RasAuto"        "Remote Access Auto Connection Manager"
call :procesar_servicio "RasMan"         "Remote Access Connection Manager"
call :procesar_servicio "SessionEnv"     "Remote Desktop Configuration"
call :procesar_servicio "TermService"    "Remote Desktop Services"
call :procesar_servicio "UmRdpService"   "Remote Desktop Services UserMode Port Redirector"
call :procesar_servicio "RpcSs"          "Remote Procedure Call (RPC)"
call :procesar_servicio "RpcLocator"     "Remote Procedure Call (RPC) Locator"
call :procesar_servicio "RemoteRegistry" "Remote Registry"
call :procesar_servicio "RemoteAccess"   "Routing and Remote Access"

echo  Activando Escritorio Remoto...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1

echo.
echo  ============================================================
ipconfig
echo  ============================================================
echo.
echo  Presiona ENTER para cerrar esta ventana...
pause >nul
exit /b 0

:: ============================================================
::  FUNCION: procesar_servicio
:: ============================================================
:procesar_servicio
set "NOMBRE_SERVICIO=%~1"
set "DESCRIPCION=%~2"

echo  Activando %DESCRIPCION%...

:: Verificar si el servicio existe
sc query "%NOMBRE_SERVICIO%" >nul 2>&1
if %errorlevel% neq 0 (
    goto :eof
)

:: Configurar inicio automatico
sc config "%NOMBRE_SERVICIO%" start= auto >nul 2>&1

:: Iniciar el servicio
sc query "%NOMBRE_SERVICIO%" 2>nul | findstr /i "RUNNING" >nul 2>&1
if %errorlevel% neq 0 (
    sc start "%NOMBRE_SERVICIO%" >nul 2>&1
    timeout /t 3 /nobreak >nul 2>&1
)

goto :eof
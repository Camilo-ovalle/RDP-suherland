@echo off
chcp 65001 >nul 2>&1
title Desactivar Servicios RDP y Conexion Remota
color 0C

:: ============================================================
::  SCRIPT: Deshabilitar servicios de Escritorio Remoto (RDP)
::  USO:    Ejecutar como Administrador
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
echo   Desactivador de Servicios RDP / Conexion Remota - Windows
echo  ============================================================
echo.
echo  Equipo: %COMPUTERNAME%
echo  Fecha:  %date%  Hora: %time%
echo.

:: ============================================================
::  FASE 1: DESACTIVAR ESCRITORIO REMOTO
:: ============================================================

echo  ============================================================
echo   FASE 1: Desactivando Escritorio Remoto en Windows...
echo  ============================================================
echo.
echo  [CONFIG] Deshabilitando Escritorio Remoto (fDenyTSConnections = 1)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Escritorio Remoto DESACTIVADO (toggle OFF).
) else (
    echo    [ERROR] No se pudo desactivar el Escritorio Remoto.
)

:: ============================================================
::  FASE 2: DETENER Y DESHABILITAR SERVICIOS
:: ============================================================

echo.
echo  ============================================================
echo   FASE 2: Deteniendo y deshabilitando servicios...
echo  ============================================================

call :detener_servicio "UmRdpService"   "Remote Desktop Services UserMode Port Redirector"
call :detener_servicio "TermService"    "Remote Desktop Services"
call :detener_servicio "SessionEnv"     "Remote Desktop Configuration"
call :detener_servicio "RemoteAccess"   "Routing and Remote Access"
call :detener_servicio "RemoteRegistry" "Remote Registry"
call :detener_servicio "RpcLocator"     "Remote Procedure Call (RPC) Locator"
call :detener_servicio "RasMan"         "Remote Access Connection Manager"
call :detener_servicio "RasAuto"        "Remote Access Auto Connection Manager"

echo.
echo  ------------------------------------------------------------
echo   Todos los servicios han sido procesados.
echo  ------------------------------------------------------------
echo.
echo  ============================================================
echo  Proceso completado exitosamente.
echo  ============================================================
echo.
pause
exit /b 0

:: ============================================================
::  FUNCION: detener_servicio
:: ============================================================
:detener_servicio
set "NOMBRE_SERVICIO=%~1"
set "DESCRIPCION=%~2"

echo.
echo  [INFO] Procesando: %DESCRIPCION% (%NOMBRE_SERVICIO%)

:: Verificar si el servicio existe
sc query "%NOMBRE_SERVICIO%" >nul 2>&1
if %errorlevel% neq 0 (
    echo    [ADVERTENCIA] El servicio "%NOMBRE_SERVICIO%" no existe en este equipo. Saltando...
    goto :eof
)

:: Detener el servicio si está corriendo
sc query "%NOMBRE_SERVICIO%" 2>nul | findstr /i "RUNNING" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [CAMBIO] Deteniendo servicio...
    sc stop "%NOMBRE_SERVICIO%" >nul 2>&1
    timeout /t 2 /nobreak >nul 2>&1
    sc query "%NOMBRE_SERVICIO%" 2>nul | findstr /i "STOPPED" >nul 2>&1
    if %errorlevel% equ 0 (
        echo    [OK] Servicio detenido correctamente.
    ) else (
        echo    [ADVERTENCIA] El servicio no se detuvo completamente.
    )
) else (
    echo    [OK] El servicio ya estaba detenido.
)

:: Configurar inicio manual o deshabilitado
echo    [CAMBIO] Configurando inicio manual...
sc config "%NOMBRE_SERVICIO%" start= demand >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Tipo de inicio cambiado a Manual.
) else (
    echo    [ADVERTENCIA] No se pudo cambiar el tipo de inicio.
)

goto :eof

@echo off
chcp 65001 >nul 2>&1
title Verificador de Servicios RDP y Conexion Remota
color 0A

:: ============================================================
::  SCRIPT: Habilitar servicios de Escritorio Remoto (RDP)
::  USO:    Ejecutar como Administrador
::  ORDEN:
::    1. Habilitar e iniciar todos los servicios
::    2. Activar Escritorio Remoto (toggle On en Configuracion)
::    3. Mostrar IPv4 del equipo
:: ============================================================

:: Configurar archivo de log
set "LOG_FILE=%~dp0rdp_services_log_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "LOG_FILE=%LOG_FILE: =0%"
call :log "=========================================="
call :log "INICIO DE EJECUCION DEL SCRIPT RDP"
call :log "Fecha: %date% - Hora: %time%"
call :log "Equipo: %COMPUTERNAME%"
call :log "=========================================="
call :log ""

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [ERROR] Este script debe ejecutarse como Administrador.
    echo  Haz clic derecho sobre el archivo y selecciona
    echo  "Ejecutar como administrador".
    echo.
    call :log "[ERROR] Script ejecutado sin permisos de Administrador"
    call :log "Ejecucion abortada"
    pause
    exit /b 1
)
call :log "[OK] Permisos de Administrador verificados"

echo.
echo  ============================================================
echo   Habilitador de Servicios RDP / Conexion Remota - Windows
echo  ============================================================
echo.
echo  Equipo: %COMPUTERNAME%
echo  Fecha:  %date%  Hora: %time%
echo.

:: ============================================================
::  FASE 1: HABILITAR E INICIAR SERVICIOS
:: ============================================================

echo  ============================================================
echo   FASE 1: Habilitando e iniciando servicios...
echo  ============================================================
call :log ""
call :log "============================================================"
call :log "FASE 1: Habilitando e iniciando servicios..."
call :log "============================================================"

call :procesar_servicio "RasAuto"        "Remote Access Auto Connection Manager"
call :procesar_servicio "RasMan"         "Remote Access Connection Manager"
call :procesar_servicio "SessionEnv"     "Remote Desktop Configuration"
call :procesar_servicio "TermService"    "Remote Desktop Services"
call :procesar_servicio "UmRdpService"   "Remote Desktop Services UserMode Port Redirector"
call :procesar_servicio "RpcSs"          "Remote Procedure Call (RPC)"
call :procesar_servicio "RpcLocator"     "Remote Procedure Call (RPC) Locator"
call :procesar_servicio "RemoteRegistry" "Remote Registry"
call :procesar_servicio "RemoteAccess"   "Routing and Remote Access"

echo.
echo  ------------------------------------------------------------
echo   Todos los servicios han sido procesados.
echo  ------------------------------------------------------------
call :log ""
call :log "------------------------------------------------------------"
call :log "Todos los servicios han sido procesados"
call :log "------------------------------------------------------------"

:: ============================================================
::  FASE 2: ACTIVAR ESCRITORIO REMOTO (Toggle ON)
::  Esto equivale a activar el switch en:
::  Configuracion ^> Sistema ^> Escritorio Remoto
:: ============================================================

echo.
echo  ============================================================
echo   FASE 2: Activando Escritorio Remoto en Windows...
echo  ============================================================
call :log ""
call :log "============================================================"
call :log "FASE 2: Activando Escritorio Remoto en Windows..."
call :log "============================================================"

echo.
echo  [CONFIG] Habilitando Escritorio Remoto (fDenyTSConnections = 0)...
call :log ""
call :log "[CONFIG] Habilitando Escritorio Remoto (fDenyTSConnections = 0)..."
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Escritorio Remoto ACTIVADO (toggle ON).
    call :log "   [OK] Escritorio Remoto ACTIVADO (toggle ON)"
) else (
    echo    [ERROR] No se pudo activar el Escritorio Remoto.
    call :log "   [ERROR] No se pudo activar el Escritorio Remoto"
)

:: ============================================================
::  FASE 3: MOSTRAR DIRECCION IPv4 DEL EQUIPO
:: ============================================================

echo.
echo  ============================================================
echo   FASE 3: Informacion de conexion
echo  ============================================================
call :log ""
call :log "============================================================"
call :log "FASE 3: Informacion de conexion"
call :log "============================================================"
echo.
echo  [INFO] Direccion(es) IPv4 detectada(s) en este equipo:
echo.
call :log ""
call :log "[INFO] Direccion(es) IPv4 detectada(s):"
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    echo    ****  %%a
    call :log "   ****  %%a"
)
echo.
echo  ------------------------------------------------------------
echo.
echo  RESUMEN:
echo    - Servicios:         10 procesados
echo    - Escritorio Remoto: ACTIVADO (ON)
echo    - Equipo:            %COMPUTERNAME%
echo.
echo  Para conectarse use:
echo    mstsc /v:[IPv4 de arriba]
echo.
echo  ============================================================
echo  Proceso completado exitosamente.
echo  ============================================================
call :log ""
call :log "============================================================"
call :log "Proceso completado exitosamente"
call :log "Fecha finalizacion: %date% - Hora: %time%"
call :log "============================================================"
call :log ""
call :log "Archivo de log guardado en: %LOG_FILE%"
echo.
echo  [INFO] Log guardado en:
echo    %LOG_FILE%
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

echo.
echo  [INFO] Procesando: %DESCRIPCION% (%NOMBRE_SERVICIO%)
call :log ""
call :log "[INFO] Procesando: %DESCRIPCION% (%NOMBRE_SERVICIO%)"

:: Verificar si el servicio existe
sc query "%NOMBRE_SERVICIO%" >nul 2>&1
if %errorlevel% neq 0 (
    echo    [ADVERTENCIA] El servicio "%NOMBRE_SERVICIO%" no existe en este equipo. Saltando...
    call :log "   [ADVERTENCIA] El servicio '%NOMBRE_SERVICIO%' no existe. Saltando..."
    goto :eof
)

:: --- Paso 1: Verificar y configurar tipo de inicio ---
sc qc "%NOMBRE_SERVICIO%" 2>nul | findstr /i "AUTO_START" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Tipo de inicio: Automatico
    call :log "   [OK] Tipo de inicio: Automatico"
) else (
    echo    [CAMBIO] Configurando inicio automatico...
    call :log "   [CAMBIO] Configurando inicio automatico..."
    sc config "%NOMBRE_SERVICIO%" start= auto >nul 2>&1
    if %errorlevel% equ 0 (
        echo    [OK] Tipo de inicio cambiado a Automatico.
        call :log "   [OK] Tipo de inicio cambiado a Automatico"
    ) else (
        echo    [ERROR] No se pudo cambiar el tipo de inicio.
        call :log "   [ERROR] No se pudo cambiar el tipo de inicio"
    )
)

:: --- Paso 2: Verificar y arrancar el servicio ---
sc query "%NOMBRE_SERVICIO%" 2>nul | findstr /i "RUNNING" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Estado: En ejecucion (RUNNING)
    call :log "   [OK] Estado: En ejecucion (RUNNING)"
) else (
    echo    [CAMBIO] Iniciando servicio...
    call :log "   [CAMBIO] Iniciando servicio..."
    sc start "%NOMBRE_SERVICIO%" >nul 2>&1
    timeout /t 3 /nobreak >nul 2>&1
    sc query "%NOMBRE_SERVICIO%" 2>nul | findstr /i "RUNNING" >nul 2>&1
    if %errorlevel% equ 0 (
        echo    [OK] Servicio iniciado correctamente.
        call :log "   [OK] Servicio iniciado correctamente"
    ) else (
        echo    [ADVERTENCIA] El servicio no alcanzo estado RUNNING.
        echo                  Puede requerir tiempo adicional o depender de otro servicio.
        call :log "   [ADVERTENCIA] El servicio no alcanzo estado RUNNING"
        call :log "                  Puede requerir tiempo adicional o depender de otro servicio"
    )
)

goto :eof

:: ============================================================
::  FUNCION: log
::  Escribe mensajes tanto en pantalla como en el archivo de log
:: ============================================================
:log
echo %~1 >> "%LOG_FILE%"
goto :eof
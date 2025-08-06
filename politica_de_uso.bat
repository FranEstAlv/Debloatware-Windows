@echo off
title Configuración de Políticas de Ejecución
color 0B

echo ================================
echo   CONFIGURANDO POLÍTICAS DE US===============
echo.

:: Ejecutar como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Este script debe ejecutarse como administrador.
    pause
    exit /b
)

:: Permitir ejecución de scripts PowerShell
powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force"

:: Desactivar reinstalación automática de apps sugeridas
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableConsumerFeatures /t REG_DWORD /d 1 /f

:: Desactivar instalación automática de apps por parte de Windows Store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f

echo.
echo ================================
echo   POLÍTICAS CONFIGURADAS
echo ================================
pause
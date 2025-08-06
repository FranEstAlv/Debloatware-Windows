@echo off
title Eliminación Agresiva de Bloatware
color 0C

echo ================================
echo   ELIMINANDO BLOATWARE
echo ================================
echo.

:: Ejecutar como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Este script debe ejecutarse como administrador.
    pause
    exit /b
)

:: PowerShell para eliminar apps innecesarias
powershell -Command "Get-AppxPackage -AllUsers ^| Where-Object {
    $_.Name -match 'Microsoft.(3DBuilder|BingNews|GetHelp|Getstarted|Messaging|MicrosoftOfficeHub|OneConnect|People|SkypeApp|SolitaireCollection|StickyNotes|Wallet|WebExperience|Xbox|ZuneMusic|ZuneVideo|YourPhone|WindowsMaps|MixedReality|FeedbackHub|Cortana|Teams|TikTok|Clipchamp|News|Weather|ToDo|Whiteboard|PowerAutomateDesktop)'
} ^| Remove-AppxPackage"

echo.
echo ================================
echo   BLOATWARE ELIMINADO
echo ================================
pause
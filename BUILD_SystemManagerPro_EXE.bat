@echo off
setlocal EnableExtensions
chcp 65001 >nul

title System Manager Pro - EXE Builder

echo.
echo ================================================
echo        SYSTEM MANAGER PRO - EXE BUILD
echo ================================================
echo.

where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo [HATA] PowerShell bulunamadi.
    pause
    exit /b 1
)

set "SCRIPT=%~dp0SystemManagerPro.ps1"
set "OUTPUT=%~dp0SystemManagerPro.exe"

if not exist "%SCRIPT%" (
    echo [HATA] SystemManagerPro.ps1 bulunamadi.
    echo.
    echo BAT ile PS1 dosyasini ayni klasore koymalisin.
    echo Klasor: %~dp0
    echo.
    pause
    exit /b 1
)

echo [1/3] ps2exe kontrol ediliyor...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-Module -ListAvailable -Name ps2exe)) { Write-Host '[INFO] ps2exe kuruluyor...' -ForegroundColor Yellow; Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop }; Import-Module ps2exe -ErrorAction Stop"
if errorlevel 1 (
    echo.
    echo [HATA] ps2exe kurulumu/yuklenmesi basarisiz oldu.
    pause
    exit /b 1
)

echo [2/3] EXE olusturuluyor...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
 "Import-Module ps2exe; Invoke-PS2EXE -InputFile '%SCRIPT%' -OutputFile '%OUTPUT%' -noConsole -title 'System Manager Pro' -description 'Modern toplu yazilim ve donanim yoneticisi' -company 'System Manager Pro' -version '1.0.0.0' -requireAdmin -ErrorAction Stop"
if errorlevel 1 (
    echo.
    echo [HATA] EXE olusturulamadi.
    echo Yukaridaki hata mesajini kontrol et.
    pause
    exit /b 1
)

if not exist "%OUTPUT%" (
    echo.
    echo [HATA] Derleme tamamlandi gibi gorundu ama EXE bulunamadi.
    pause
    exit /b 1
)

echo [3/3] Kontrol tamamlandi.
echo.
echo ================================================
echo   TAMAM! SystemManagerPro.exe olusturuldu.
echo ================================================
echo.
echo EXE: %OUTPUT%
echo.
pause
endlocal

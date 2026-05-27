@echo off
title Kripto Kaldırma Sihirbazı
echo Kripto Kaldırma Sihirbazı başlatılıyor...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
pause

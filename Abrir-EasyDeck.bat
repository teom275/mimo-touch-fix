@echo off
title EasyDeck Launcher
cd /d "%~dp0"
echo Iniciando EasyDeck Touch Controller...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0easydeck\server.ps1"

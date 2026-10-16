@echo off
cd /d "%~dp0"
echo Requesting administrator privileges to apply Mimo touch mapping...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"\"%~dp0Fix-MimoTouchMapping.ps1\"\"' -Verb RunAs"

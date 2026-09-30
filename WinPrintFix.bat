@echo off
setlocal
cd /d "%~dp0"
echo ========================================================
echo   WinPrintFix: Windows Print Spooler & Network Repair
echo ========================================================
echo Requesting Administrator privileges...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\WinPrintFix.ps1"
endlocal

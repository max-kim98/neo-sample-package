@echo off
setlocal

if not exist .\.backend\pid exit /b 0
set /p PID=<.\.backend\pid
if "%PID%"=="" (
  del /f /q .\.backend\pid >nul 2>&1
  exit /b 0
)

taskkill /F /PID %PID% >nul 2>&1

del /f /q .\.backend\pid >nul 2>&1

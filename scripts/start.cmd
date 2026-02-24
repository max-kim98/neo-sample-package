@echo off
setlocal enabledelayedexpansion

set "BIN="
if not "%PROJECT_NAME%"=="" set "BIN=.\.backend\%PROJECT_NAME%.exe"

if "%BIN%"=="" (
  for %%F in (.\.backend\*.exe) do (
    set "BIN=%%F"
    goto :run
  )
)

:run
if "%BIN%"=="" (
  echo backend executable not found in .\.backend
  exit /b 1
)

if "%LISTEN_ADDR%"=="" set "LISTEN_ADDR=http://127.0.0.1:12345"
if "%DATABASE_PATH%"=="" set "DATABASE_PATH=..\storage\.data.json"

"%BIN%" --listen "%LISTEN_ADDR%" --database "%DATABASE_PATH%" --pid ".\\.backend\\pid"

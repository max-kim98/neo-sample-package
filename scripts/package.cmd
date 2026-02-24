@echo off
setlocal enabledelayedexpansion

for %%I in ("%~dp0..") do set "ROOT=%%~fI"
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\project-name.ps1"`) do set "PROJECT_NAME=%%I"

if "%PROJECT_NAME%"=="" (
  echo failed to resolve project name
  exit /b 1
)

set "PROJECT_NAME=%PROJECT_NAME%"
node "%ROOT%\scripts\set-frontend-homepage.js" "%PROJECT_NAME%" || exit /b 1

pushd "%ROOT%\frontend"
if not exist "node_modules" (
  call npm install --no-audit --no-fund || exit /b 1
) else (
  echo frontend\node_modules already exists, skipping npm install
)
set "PUBLIC_URL=/web/apps/%PROJECT_NAME%"
call npm run build || exit /b 1
popd

if not exist "%ROOT%\frontend\build\.backend" mkdir "%ROOT%\frontend\build\.backend"

pushd "%ROOT%"
set CGO_ENABLED=0
set GOOS=linux
set GOARCH=amd64
go build -o "%ROOT%\frontend\build\.backend\%PROJECT_NAME%" . || exit /b 1
set GOOS=windows
go build -o "%ROOT%\frontend\build\.backend\%PROJECT_NAME%.exe" . || exit /b 1
set GOOS=
set GOARCH=
popd

copy "%ROOT%\scripts\start.sh" "%ROOT%\frontend\build\.backend\start.sh" >nul || exit /b 1
copy "%ROOT%\scripts\stop.sh" "%ROOT%\frontend\build\.backend\stop.sh" >nul || exit /b 1
copy "%ROOT%\scripts\start.cmd" "%ROOT%\frontend\build\.backend\start.cmd" >nul || exit /b 1
copy "%ROOT%\scripts\stop.cmd" "%ROOT%\frontend\build\.backend\stop.cmd" >nul || exit /b 1
copy "%ROOT%\.backend.yml" "%ROOT%\frontend\build\.backend.yml" >nul || exit /b 1

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\verify-structure.ps1" -OutputDir "%ROOT%\frontend\build" -ProjectName "%PROJECT_NAME%" || exit /b 1

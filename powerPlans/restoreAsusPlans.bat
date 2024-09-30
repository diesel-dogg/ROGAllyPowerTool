@echo off
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
cd /d "%~dp0"
POWERCFG /SETACTIVE 381b4222-f694-41f0-9685-ff5bb260df2e
powercfg /delete 27fa6203-3987-4dcc-918d-748559d549ec
powercfg /delete 64a64f24-65b9-4b56-befd-5ec1eaced9b3
powercfg /delete 6fecc5ae-f350-48a5-b669-b472cb895ccf

powercfg /import "%~dp0performance.pow" 27fa6203-3987-4dcc-918d-748559d549ec
powercfg /import "%~dp0silent.pow" 64a64f24-65b9-4b56-befd-5ec1eaced9b3
powercfg /import "%~dp0turbo.pow" 6fecc5ae-f350-48a5-b669-b472cb895ccf
timeout /t 10
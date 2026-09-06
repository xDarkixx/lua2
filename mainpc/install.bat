@echo off
setlocal
cd /d "%~dp0.."
where py >nul 2>nul
if %errorlevel%==0 (
  py mainpc\install.py %*
  goto :end
)
where python >nul 2>nul
if %errorlevel%==0 (
  python mainpc\install.py %*
  goto :end
)
echo [BULDACITY] Python 3 wurde nicht gefunden.
echo Bitte Python 3 installieren und danach diesen Installer erneut starten.
:end
pause

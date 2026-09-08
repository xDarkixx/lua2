@echo off
setlocal
cd /d "%~dp0"

echo ========================================
echo SchematicTxtGenerator - AUTO BUILD
echo ========================================
echo.

where py >nul 2>&1
if errorlevel 1 (
  echo Python 3 wurde nicht gefunden.
  echo Bitte Python 3 installieren und den Build erneut starten.
  echo.
  pause
  exit /b 1
)

if not exist .venv\Scripts\python.exe py -3 -m venv .venv
if errorlevel 1 goto :error

.venv\Scripts\python.exe -m pip install --upgrade pip
if errorlevel 1 goto :error
.venv\Scripts\python.exe -m pip install -r requirements.txt
if errorlevel 1 goto :error

rem Tests muessen zuerst erfolgreich sein. Erst danach wird die EXE gebaut.
.venv\Scripts\python.exe build_all.py
if errorlevel 1 goto :error

echo.
echo ========================================
echo FERTIG!
echo EXE: dist\SchematicTxtGenerator.exe
echo ========================================
echo.
pause
exit /b 0

:error
echo.
echo BUILD ABGEBROCHEN - Tests oder Build fehlgeschlagen.
pause
exit /b 1

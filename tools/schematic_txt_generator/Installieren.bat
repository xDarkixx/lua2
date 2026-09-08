@echo off
cd /d "%~dp0"
echo ==========================================
echo SchematicTxtGenerator - Installation
 echo ==========================================
py -3 -m venv .venv
if errorlevel 1 goto :error
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install -r requirements.txt
if errorlevel 1 goto :error
echo.
echo Installation fertig.
echo Starte jetzt Start_Generator.bat
pause
exit /b 0
:error
echo Installation fehlgeschlagen. Python 3 muss installiert sein.
pause
exit /b 1

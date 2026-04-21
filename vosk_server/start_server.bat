@echo off
echo ========================================
echo  Vosk Speech Recognition Server Setup
echo ========================================
echo.

set PYTHON="C:\Users\Arvi_Salek\AppData\Local\Python\pythoncore-3.14-64\python.exe"

echo Checking for existing server on port 8765...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8765 "') do (
    echo Killing existing process PID %%a...
    taskkill /PID %%a /F >nul 2>&1
)
echo Port 8765 is clear.
echo.

echo Installing Python dependencies...
%PYTHON% -m pip install -r requirements.txt
if errorlevel 1 (
    echo.
    echo ERROR: Failed to install dependencies.
    echo Make sure Python and pip are installed.
    pause
    exit /b 1
)

echo.
echo Dependencies installed successfully!
echo.
echo Starting Vosk server...
echo (The model will auto-download on first run, ~50MB)
echo.
%PYTHON% vosk_server.py
pause

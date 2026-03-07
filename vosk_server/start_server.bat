@echo off
echo ========================================
echo  Vosk Speech Recognition Server Setup
echo ========================================
echo.

echo Installing Python dependencies...
pip install -r requirements.txt
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
python vosk_server.py
pause

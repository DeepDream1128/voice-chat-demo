@echo on
echo ================================================
echo   Voice Chat Demo - Run
echo ================================================
echo.

set "CONDA_DIR=%USERPROFILE%\miniconda3"
set "ENV_NAME=voice-chat"

REM ========== 1. Activate conda env ==========
echo [1/3] Activating conda env %ENV_NAME%...
set "PATH=%CONDA_DIR%;%CONDA_DIR%\Scripts;%CONDA_DIR%\Library\bin;%CONDA_DIR%\condabin;%PATH%"
call "%CONDA_DIR%\Scripts\activate.bat" %ENV_NAME%

python --version
if %errorlevel% neq 0 (
    echo [ERROR] conda env not found, run install.bat first
    pause
    exit /b 1
)

REM ========== 2. Check / Start Ollama ==========
echo [2/3] Checking Ollama...
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | findstr /I "ollama.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo Ollama not running, starting...
    where ollama >nul 2>&1
    if %errorlevel% neq 0 (
        if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
            start "" "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" serve
        ) else if exist "C:\Program Files\Ollama\ollama.exe" (
            start "" "C:\Program Files\Ollama\ollama.exe" serve
        ) else (
            echo [ERROR] Ollama not found, please install from https://ollama.com
            pause
            exit /b 1
        )
    ) else (
        start "" ollama serve
    )
    echo Waiting for Ollama to start...
    timeout /t 5 /nobreak >nul
)
echo Ollama is running.

REM ========== 3. Run voice chat ==========
echo [3/3] Starting voice chat...
echo.
python voice_chat.py

pause

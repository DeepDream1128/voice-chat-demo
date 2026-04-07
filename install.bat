@echo off
echo ================================================
echo   Voice Chat Demo - Auto Installer
echo   Miniconda + Python 3.11 + CUDA 12.1
echo ================================================
echo.

set CONDA_DIR=%USERPROFILE%\miniconda3
set ENV_NAME=voice-chat
set INSTALLER=Miniconda3-latest-Windows-x86_64.exe

REM ========== 1. Check / Install Miniconda ==========
where conda >nul 2>&1
if %errorlevel% equ 0 (
    echo [1/5] Miniconda found, skip
) else (
    if exist "%CONDA_DIR%\Scripts\conda.exe" (
        echo [1/5] Miniconda found at %CONDA_DIR%, skip download
    ) else (
        echo [1/5] Downloading Miniconda...
        curl -L -o %INSTALLER% https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe
        if %errorlevel% neq 0 (
            echo [ERROR] Download failed, check your network
            pause
            exit /b 1
        )
        echo   Installing Miniconda to %CONDA_DIR% ...
        start /wait "" %INSTALLER% /InstallationType=JustMe /RegisterPython=0 /AddToPath=0 /S /D=%CONDA_DIR%
        del %INSTALLER%
        echo   Miniconda installed
    )
)

REM Activate conda
if exist "%CONDA_DIR%\Scripts\activate.bat" (
    call "%CONDA_DIR%\Scripts\activate.bat"
) else (
    call conda activate 2>nul
)

REM Make sure conda is on PATH
where conda >nul 2>&1
if %errorlevel% neq 0 (
    set "PATH=%CONDA_DIR%;%CONDA_DIR%\Scripts;%CONDA_DIR%\Library\bin;%PATH%"
)

REM ========== Set Tsinghua mirror for conda ==========
echo Setting conda mirror (tsinghua)...
call conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
call conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
call conda config --set show_channel_urls yes

REM ========== 2. Create Python 3.11 conda env ==========
echo [2/5] Creating conda env (%ENV_NAME%, Python 3.11)...
call conda env list | findstr /C:"%ENV_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo   Env %ENV_NAME% exists, skip
) else (
    call conda create -n %ENV_NAME% python=3.11 -y
)
call conda activate %ENV_NAME%

REM Confirm Python version
python --version

REM ========== 3. Install PyTorch ==========
echo [3/5] Installing PyTorch (CUDA 12.1)...
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121

REM ========== 4. Install dependencies ==========
echo [4/5] Installing project dependencies...
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

REM ========== 5. editdistance fallback ==========
echo [5/5] Installing editdistance...
pip install editdistance >nul 2>&1
if %errorlevel% neq 0 (
    echo   editdistance failed, trying editdistance-s...
    pip install editdistance-s
)

echo.
echo ================================================
echo   Done!
echo.
echo   How to run:
echo   1. Make sure Ollama is running
echo   2. conda activate %ENV_NAME%
echo   3. cd to this folder, then:
echo      python voice_chat.py
echo ================================================
pause

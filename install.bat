@echo on
echo ================================================
echo   Voice Chat Demo - Auto Installer
echo   Miniconda + Python 3.11 + CUDA 12.1
echo ================================================
echo.

set "CONDA_DIR=%USERPROFILE%\miniconda3"
set "ENV_NAME=voice-chat"
set "INSTALLER=%USERPROFILE%\Miniconda3-latest-Windows-x86_64.exe"
set "CONDA_EXE=%CONDA_DIR%\Scripts\conda.exe"

REM ========== 1. Check / Install Miniconda ==========
if exist "%CONDA_EXE%" (
    echo [1/5] Miniconda found, skip download
    goto conda_ready
)

where conda >nul 2>&1
if %errorlevel% equ 0 (
    echo [1/5] Miniconda found in PATH, skip
    set "CONDA_EXE=conda"
    goto conda_ready
)

REM If directory exists but conda.exe missing, remove broken install
if exist "%CONDA_DIR%" (
    echo [1/5] Found broken Miniconda install, cleaning up...
    rmdir /s /q "%CONDA_DIR%"
)

echo [1/5] Downloading Miniconda from tsinghua mirror...
curl -L -o "%INSTALLER%" https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Windows-x86_64.exe
if %errorlevel% neq 0 (
    echo [ERROR] Download failed, check your network
    pause
    exit /b 1
)
echo Installing Miniconda to %CONDA_DIR% ...
start /wait "" "%INSTALLER%" /InstallationType=JustMe /RegisterPython=0 /AddToPath=1 /S /D=%CONDA_DIR%
del "%INSTALLER%"

REM Verify install succeeded
if not exist "%CONDA_EXE%" (
    echo [ERROR] Miniconda install failed, conda.exe not found
    pause
    exit /b 1
)
echo Miniconda installed

:conda_ready
REM Add conda to PATH for this session
set "PATH=%CONDA_DIR%;%CONDA_DIR%\Scripts;%CONDA_DIR%\Library\bin;%CONDA_DIR%\condabin;%PATH%"

REM Add conda to user PATH permanently if missing
reg query "HKCU\Environment" /v Path 2>nul | findstr /I /C:"miniconda3" >nul 2>&1
if %errorlevel% neq 0 (
    echo Adding conda to user PATH permanently...
    reg query "HKCU\Environment" /v Path >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
            reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "%%B;%CONDA_DIR%;%CONDA_DIR%\Scripts;%CONDA_DIR%\condabin" /f
        )
    ) else (
        reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "%CONDA_DIR%;%CONDA_DIR%\Scripts;%CONDA_DIR%\condabin" /f
    )
    echo Conda added to user PATH.
)

REM Verify conda works
echo Verifying conda...
"%CONDA_EXE%" --version
if %errorlevel% neq 0 (
    echo [ERROR] conda not working
    pause
    exit /b 1
)

REM Initialize conda for this shell
call "%CONDA_DIR%\Scripts\activate.bat"

REM ========== Set Tsinghua mirror for conda ==========
echo Setting conda mirror...
"%CONDA_EXE%" config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
"%CONDA_EXE%" config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
"%CONDA_EXE%" config --set show_channel_urls yes

REM ========== 2. Create Python 3.11 conda env ==========
echo [2/5] Creating conda env (%ENV_NAME%, Python 3.11)...
"%CONDA_EXE%" env list 2>nul | findstr /C:"%ENV_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo Env %ENV_NAME% exists, skip
) else (
    call "%CONDA_EXE%" create -n %ENV_NAME% python=3.11 -y
)

REM Activate the env
call "%CONDA_DIR%\Scripts\activate.bat" %ENV_NAME%

REM Confirm Python version
python --version
if %errorlevel% neq 0 (
    echo [ERROR] Python not available after activation
    pause
    exit /b 1
)
echo.

REM ========== 3. Install PyTorch ==========
echo [3/5] Installing PyTorch CUDA 12.1 ...
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121

REM ========== 4. Install dependencies ==========
echo [4/5] Installing project dependencies...
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

REM ========== 5. editdistance fallback ==========
echo [5/5] Installing editdistance...
pip install editdistance -i https://pypi.tuna.tsinghua.edu.cn/simple >nul 2>&1
if %errorlevel% neq 0 (
    echo editdistance failed, trying editdistance-s...
    pip install editdistance-s -i https://pypi.tuna.tsinghua.edu.cn/simple
)

echo.
echo ================================================
echo   Done!
echo.
echo   How to run:
echo   1. Make sure Ollama is running
echo   2. Open a NEW cmd window and run:
echo      conda activate %ENV_NAME%
echo   3. cd to this folder, then:
echo      python voice_chat.py
echo ================================================
pause

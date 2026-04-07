@echo on
echo ================================================
echo   CosyVoice Install Script
echo ================================================
echo.

set "CONDA_DIR=%USERPROFILE%\miniconda3"
set "ENV_NAME=voice-chat"
set "SCRIPT_DIR=%~dp0"

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

REM ========== 2. Find CosyVoice source ==========
echo [2/3] Looking for CosyVoice source in %SCRIPT_DIR% ...

set "COSY_DIR="

if exist "%SCRIPT_DIR%CosyVoice\setup.py" set "COSY_DIR=%SCRIPT_DIR%CosyVoice"
if exist "%SCRIPT_DIR%CosyVoice2\setup.py" set "COSY_DIR=%SCRIPT_DIR%CosyVoice2"
if exist "%SCRIPT_DIR%cosyvoice\setup.py" set "COSY_DIR=%SCRIPT_DIR%cosyvoice"
if exist "%SCRIPT_DIR%cosyvoice2\setup.py" set "COSY_DIR=%SCRIPT_DIR%cosyvoice2"
if exist "%SCRIPT_DIR%CosyVoice-main\setup.py" set "COSY_DIR=%SCRIPT_DIR%CosyVoice-main"
if exist "%SCRIPT_DIR%CosyVoice2-main\setup.py" set "COSY_DIR=%SCRIPT_DIR%CosyVoice2-main"

REM Also check for pyproject.toml if no setup.py
if not defined COSY_DIR (
    if exist "%SCRIPT_DIR%CosyVoice\pyproject.toml" set "COSY_DIR=%SCRIPT_DIR%CosyVoice"
    if exist "%SCRIPT_DIR%CosyVoice2\pyproject.toml" set "COSY_DIR=%SCRIPT_DIR%CosyVoice2"
    if exist "%SCRIPT_DIR%cosyvoice\pyproject.toml" set "COSY_DIR=%SCRIPT_DIR%cosyvoice"
    if exist "%SCRIPT_DIR%cosyvoice2\pyproject.toml" set "COSY_DIR=%SCRIPT_DIR%cosyvoice2"
    if exist "%SCRIPT_DIR%CosyVoice-main\pyproject.toml" set "COSY_DIR=%SCRIPT_DIR%CosyVoice-main"
    if exist "%SCRIPT_DIR%CosyVoice2-main\pyproject.toml" set "COSY_DIR=%SCRIPT_DIR%CosyVoice2-main"
)

if not defined COSY_DIR (
    echo [ERROR] CosyVoice source not found!
    echo.
    echo Please put CosyVoice source folder here:
    echo   %SCRIPT_DIR%
    echo.
    echo Expected folder names: CosyVoice, CosyVoice2, cosyvoice, CosyVoice-main, etc.
    echo The folder should contain setup.py or pyproject.toml
    echo.
    echo Current subfolders:
    dir /b /ad "%SCRIPT_DIR%"
    pause
    exit /b 1
)

echo Found CosyVoice at: %COSY_DIR%

REM ========== 3. Install CosyVoice ==========
echo [3/3] Installing CosyVoice from source...
cd /d "%COSY_DIR%"

if exist "requirements.txt" (
    echo Installing CosyVoice requirements...
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
)

pip install -e . -i https://pypi.tuna.tsinghua.edu.cn/simple

if %errorlevel% neq 0 (
    echo [ERROR] CosyVoice install failed
    pause
    exit /b 1
)

echo.
echo ================================================
echo   CosyVoice installed successfully!
echo   You can now run: run.bat
echo ================================================
pause

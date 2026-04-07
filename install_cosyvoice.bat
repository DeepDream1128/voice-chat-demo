@echo on
echo ================================================
echo   CosyVoice Install Script
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

REM ========== 2. Find CosyVoice source ==========
echo [2/3] Looking for CosyVoice source...

REM Try common folder names
if exist "%~dp0CosyVoice\setup.py" (
    set "COSY_DIR=%~dp0CosyVoice"
    goto cosy_found
)
if exist "%~dp0CosyVoice2\setup.py" (
    set "COSY_DIR=%~dp0CosyVoice2"
    goto cosy_found
)
if exist "%~dp0cosyvoice\setup.py" (
    set "COSY_DIR=%~dp0cosyvoice"
    goto cosy_found
)

REM Search for setup.py containing cosyvoice in subdirectories
for /d %%D in ("%~dp0*") do (
    if exist "%%D\setup.py" (
        findstr /I /C:"cosyvoice" "%%D\setup.py" >nul 2>&1
        if %errorlevel% equ 0 (
            set "COSY_DIR=%%D"
            goto cosy_found
        )
    )
)

echo [ERROR] CosyVoice source not found in this folder.
echo Please put CosyVoice source code in a subfolder like:
echo   %~dp0CosyVoice\
pause
exit /b 1

:cosy_found
echo Found CosyVoice at: %COSY_DIR%

REM ========== 3. Install CosyVoice ==========
echo [3/3] Installing CosyVoice from source...
cd /d "%COSY_DIR%"

REM Install dependencies if requirements exist
if exist "requirements.txt" (
    echo Installing CosyVoice requirements...
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
)

REM Install in editable mode
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

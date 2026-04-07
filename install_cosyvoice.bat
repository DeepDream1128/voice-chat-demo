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
echo [2/3] Looking for CosyVoice source...

set "COSY_DIR="

REM Check for cosyvoice python package inside folder
if exist "%SCRIPT_DIR%CosyVoice\cosyvoice" set "COSY_DIR=%SCRIPT_DIR%CosyVoice"
if exist "%SCRIPT_DIR%CosyVoice2\cosyvoice" set "COSY_DIR=%SCRIPT_DIR%CosyVoice2"
if exist "%SCRIPT_DIR%cosyvoice\cosyvoice" set "COSY_DIR=%SCRIPT_DIR%cosyvoice"
if exist "%SCRIPT_DIR%CosyVoice-main\cosyvoice" set "COSY_DIR=%SCRIPT_DIR%CosyVoice-main"

if not defined COSY_DIR (
    echo [ERROR] CosyVoice source not found!
    echo Current subfolders:
    dir /b /ad "%SCRIPT_DIR%"
    pause
    exit /b 1
)

echo Found CosyVoice at: %COSY_DIR%

REM ========== 3. Install CosyVoice ==========
echo [3/3] Installing CosyVoice...
cd /d "%COSY_DIR%"

REM Install setuptools first (needed by some deps like openai-whisper)
pip install "setuptools<81" -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install hyperpyyaml -i https://pypi.tuna.tsinghua.edu.cn/simple

REM Install requirements
if exist "requirements.txt" (
    echo Installing CosyVoice requirements...
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
)

REM Install third_party packages if they exist
if exist "third_party" (
    echo Installing third_party packages...
    for /d %%D in (third_party\*) do (
        if exist "%%D\setup.py" (
            echo   Installing %%D ...
            pip install -e "%%D" -i https://pypi.tuna.tsinghua.edu.cn/simple
        )
        if exist "%%D\pyproject.toml" (
            echo   Installing %%D ...
            pip install -e "%%D" -i https://pypi.tuna.tsinghua.edu.cn/simple
        )
    )
)

REM Add CosyVoice root to Python path via .pth file
echo Installing CosyVoice to Python path...
for /f "delims=" %%P in ('python -c "import site; print(site.getsitepackages()[0])"') do set "SITE_PKG=%%P"
echo %COSY_DIR%> "%SITE_PKG%\cosyvoice-source.pth"
echo Added %COSY_DIR% to %SITE_PKG%\cosyvoice-source.pth

REM Verify import works
python -c "from cosyvoice import CosyVoice2; print('CosyVoice2 import OK')"
if %errorlevel% neq 0 (
    echo [WARNING] CosyVoice2 import failed, trying CosyVoice...
    python -c "import cosyvoice; print('cosyvoice import OK')"
    if %errorlevel% neq 0 (
        echo [ERROR] CosyVoice install failed
        pause
        exit /b 1
    )
)

echo.
echo ================================================
echo   CosyVoice installed successfully!
echo   You can now run: run.bat
echo ================================================
pause

@echo off
chcp 65001 >nul
echo ================================================
echo   Voice Chat Demo 一键安装脚本
echo   自动安装 Miniconda + Python 3.11 环境
echo ================================================
echo.

set CONDA_DIR=%USERPROFILE%\miniconda3
set ENV_NAME=voice-chat
set INSTALLER=Miniconda3-latest-Windows-x86_64.exe

REM ========== 1. 检查/安装 Miniconda ==========
where conda >nul 2>&1
if %errorlevel% equ 0 (
    echo [1/5] Miniconda 已安装，跳过
) else (
    if exist "%CONDA_DIR%\Scripts\conda.exe" (
        echo [1/5] Miniconda 已安装在 %CONDA_DIR%，跳过下载
    ) else (
        echo [1/5] 下载 Miniconda...
        curl -L -o %INSTALLER% https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe
        if %errorlevel% neq 0 (
            echo [错误] 下载失败，请检查网络
            pause
            exit /b 1
        )
        echo   安装 Miniconda 到 %CONDA_DIR% ...
        start /wait "" %INSTALLER% /InstallationType=JustMe /RegisterPython=0 /AddToPath=0 /S /D=%CONDA_DIR%
        del %INSTALLER%
        echo   Miniconda 安装完成
    )
)

REM 激活 conda
if exist "%CONDA_DIR%\Scripts\activate.bat" (
    call "%CONDA_DIR%\Scripts\activate.bat"
) else (
    call conda activate 2>nul
)

REM 确认 conda 可用
where conda >nul 2>&1
if %errorlevel% neq 0 (
    set "PATH=%CONDA_DIR%;%CONDA_DIR%\Scripts;%CONDA_DIR%\Library\bin;%PATH%"
)

REM ========== 2. 创建 Python 3.11 conda 环境 ==========
echo [2/5] 创建 conda 环境 (%ENV_NAME%, Python 3.11)...
call conda env list | findstr /C:"%ENV_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo   环境 %ENV_NAME% 已存在，跳过创建
) else (
    call conda create -n %ENV_NAME% python=3.11 -y
)
call conda activate %ENV_NAME%

REM 确认 Python 版本
python --version

REM ========== 3. 安装 PyTorch ==========
echo [3/5] 安装 PyTorch (CUDA 12.1)...
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu121

REM ========== 4. 安装其他依赖 ==========
echo [4/5] 安装项目依赖...
pip install -r requirements.txt

REM ========== 5. editdistance fallback ==========
echo [5/5] 安装 editdistance...
pip install editdistance >nul 2>&1
if %errorlevel% neq 0 (
    echo   editdistance 编译失败，改装 editdistance-s...
    pip install editdistance-s
)

echo.
echo ================================================
echo   安装完成！
echo.
echo   运行方式:
echo   1. 确保 Ollama 已启动
echo   2. 打开 Anaconda Prompt 或执行:
echo      conda activate %ENV_NAME%
echo   3. cd 到本目录，运行:
echo      python voice_chat.py
echo ================================================
pause

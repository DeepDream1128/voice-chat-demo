@echo off
chcp 65001 >nul
echo ============================================
echo   语音对话系统 - Windows 环境一键安装脚本
echo ============================================
echo.

:: 检查 Python
echo [1/6] 检查 Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到 Python，请先安装 Python 3.10+
    echo 下载地址: https://www.python.org/downloads/
    echo 安装时务必勾选 "Add Python to PATH"
    pause
    exit /b 1
)
python --version
echo.

:: 检查 Git
echo [2/6] 检查 Git...
git --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到 Git，请先安装 Git
    echo 下载地址: https://git-scm.com/download/win
    pause
    exit /b 1
)
git --version
echo.

:: 检查 CUDA (可选)
echo [3/6] 检查 CUDA...
nvidia-smi >nul 2>&1
if errorlevel 1 (
    echo [警告] 未检测到 NVIDIA GPU 驱动，模型将使用 CPU 运行（较慢）
    set "TORCH_INDEX=https://download.pytorch.org/whl/cpu"
) else (
    echo 检测到 NVIDIA GPU:
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    set "TORCH_INDEX=https://download.pytorch.org/whl/cu121"
)
echo.

:: 创建虚拟环境
echo [4/6] 创建 Python 虚拟环境...
if exist venv (
    echo 虚拟环境已存在，跳过创建
) else (
    python -m venv venv
)
call venv\Scripts\activate.bat
echo 虚拟环境已激活
echo.

:: 安装 PyTorch
echo [5/6] 安装 PyTorch...
pip install torch torchaudio --index-url %TORCH_INDEX%
echo.

:: 安装依赖
echo [6/6] 安装项目依赖...
pip install sounddevice soundfile numpy pynput openai funasr modelscope

:: 安装 CosyVoice 2
echo.
echo ============================================
echo   安装 CosyVoice 2 (TTS 引擎)
echo ============================================
if exist CosyVoice (
    echo CosyVoice 目录已存在，跳过克隆
) else (
    git clone --recursive https://github.com/FunAudioLLM/CosyVoice.git
)
cd CosyVoice
pip install -e .
cd ..
echo.

:: 安装 Ollama
echo ============================================
echo   安装 Ollama (本地大模型)
echo ============================================
ollama --version >nul 2>&1
if errorlevel 1 (
    echo Ollama 未安装，正在下载安装程序...
    curl -L -o OllamaSetup.exe https://ollama.com/download/OllamaSetup.exe
    echo.
    echo 请手动运行 OllamaSetup.exe 完成安装
    echo 安装完成后重新运行本脚本，或手动执行:
    echo   ollama pull deepseek-r1:1.5b
    echo.
) else (
    echo Ollama 已安装:
    ollama --version
    echo.
    echo 拉取 DeepSeek 模型...
    ollama pull deepseek-r1:1.5b
)

echo.
echo ============================================
echo   安装完成！
echo ============================================
echo.
echo 使用方法:
echo   1. 确保 Ollama 正在运行 (ollama serve)
echo   2. 激活虚拟环境: venv\Scripts\activate
echo   3. 运行程序: python voice_chat.py
echo   4. 按住空格键说话，松开等待回复，ESC 退出
echo.
pause

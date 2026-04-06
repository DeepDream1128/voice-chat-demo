@echo off
echo ============================================
echo   Voice Chat - Windows Setup Script
echo ============================================
echo.

:: Check Python
echo [1/6] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Please install Python 3.10+
    echo Download: https://www.python.org/downloads/
    echo IMPORTANT: Check "Add Python to PATH" during install
    pause
    exit /b 1
)
python --version
echo.

:: Check Git
echo [2/6] Checking Git...
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git not found. Please install Git
    echo Download: https://git-scm.com/download/win
    pause
    exit /b 1
)
git --version
echo.

:: Check GPU
echo [3/6] Checking GPU...
nvidia-smi >nul 2>&1
if errorlevel 1 (
    echo [WARN] No NVIDIA GPU detected, will use CPU (slower)
    set "TORCH_INDEX=https://download.pytorch.org/whl/cpu"
) else (
    echo NVIDIA GPU detected:
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    set "TORCH_INDEX=https://download.pytorch.org/whl/cu121"
)
echo.

:: Create venv
echo [4/6] Creating Python virtual environment...
if exist venv (
    echo venv already exists, skipping
) else (
    python -m venv venv
)
call venv\Scripts\activate.bat
echo venv activated
echo.

:: Install PyTorch
echo [5/6] Installing PyTorch...
pip install torch torchaudio --index-url %TORCH_INDEX%
echo.

:: Install dependencies
echo [6/6] Installing project dependencies...
pip install sounddevice soundfile numpy pynput openai funasr modelscope
echo.

:: Install CosyVoice 2
echo ============================================
echo   Installing CosyVoice 2 (TTS engine)
echo ============================================
if exist CosyVoice (
    echo CosyVoice directory exists, skipping clone
) else (
    git clone --recursive https://github.com/FunAudioLLM/CosyVoice.git
)
cd CosyVoice
pip install -e .
cd ..
echo.

:: Check Ollama
echo ============================================
echo   Checking Ollama (Local LLM)
echo ============================================
ollama --version >nul 2>&1
if errorlevel 1 (
    echo Ollama not installed.
    echo Please download and install from: https://ollama.com/download
    echo After install, run: ollama pull deepseek-r1:1.5b
) else (
    echo Ollama found:
    ollama --version
    echo Pulling DeepSeek model...
    ollama pull deepseek-r1:1.5b
)

echo.
echo ============================================
echo   Setup Complete!
echo ============================================
echo.
echo How to use:
echo   1. Make sure Ollama is running (ollama serve)
echo   2. Activate venv: venv\Scripts\activate
echo   3. Run: python voice_chat.py
echo   4. Hold SPACE to talk, release to get reply, ESC to quit
echo.
pause

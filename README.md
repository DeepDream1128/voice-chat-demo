# Voice Chat Demo (Local Only)

这个项目实现了一个完全本地运行的语音对话系统，集成了 STT (SenseVoice)、LLM (DeepSeek via Ollama) 和 TTS (CosyVoice 2)。

## 环境准备
1. **Python**: 建议使用 Python 3.10+。
2. **CUDA**: 确保已安装对应的 CUDA Toolkit (建议 11.8+ 或 12.x)。
3. **系统依赖**:
   - 安装 PortAudio (用于 sounddevice 录音):
     - macOS: `brew install portaudio`
     - Ubuntu/Debian: `sudo apt install libportaudio2`
   - 安装 FFmpeg (用于音视频处理):
     - macOS: `brew install ffmpeg`
     - Ubuntu/Debian: `sudo apt install ffmpeg`

## 组件安装与配置

### 1. 安装 Python 依赖
```bash
pip install -r requirements.txt
```

### 2. Ollama & DeepSeek
- 下载并安装 [Ollama](https://ollama.com/)。
- 启动 Ollama 服务。
- 运行以下命令拉取并运行 DeepSeek 模型 (以 deepseek-r1:1.5b 为例):
  ```bash
  ollama run deepseek-r1:1.5b
  ```

### 3. 模型下载
项目会自动从 ModelScope 下载 SenseVoice 和 CosyVoice 2 模型，初次运行可能较慢。

## 运行方法
1. 确保 Ollama 服务已启动 (`ollama serve`)。
2. 运行脚本:
   ```bash
   python voice_chat.py
   ```
3. 按住**空格键**开始录音，松开即停止，系统会自动处理语音识别、大模型回复和语音合成播放。

"""
本地语音对话系统 Demo
STT: SenseVoice (FunASR)
LLM: Ollama (DeepSeek 本地模型)
TTS: CosyVoice (自动适配 v1/v2/v3)
"""

import os
import sys
import tempfile
import threading
import numpy as np
import sounddevice as sd
import soundfile as sf
from pynput import keyboard
from openai import OpenAI

# ============ 配置 ============
SAMPLE_RATE = 16000
CHANNELS = 1
OLLAMA_BASE_URL = "http://localhost:11434/v1"
OLLAMA_MODEL = "deepseek-r1:7b"
STT_MODEL = "iic/paraformer-zh"
TTS_SPEAKER = "中文女"

# CosyVoice 模型路径（会自动从 ModelScope 下载）
COSYVOICE_MODEL = "iic/CosyVoice-300M-SFT"

# CosyVoice 源码路径（相对于本脚本）
COSYVOICE_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "CosyVoice")

# ============ 全局状态 ============
is_recording = False
audio_chunks = []
lock = threading.Lock()


def init_stt():
    """初始化 Paraformer STT 模型"""
    print("[初始化] 加载 Paraformer 模型...")
    from funasr import AutoModel
    model = AutoModel(model=STT_MODEL)
    print("[初始化] Paraformer 加载完成")
    return model


def init_tts():
    """初始化 CosyVoice TTS 模型（官方推荐方式）"""
    print("[初始化] 加载 CosyVoice 模型...")

    # 添加 CosyVoice 源码和 third_party 到 Python 路径
    matcha_path = os.path.join(COSYVOICE_ROOT, "third_party", "Matcha-TTS")
    if COSYVOICE_ROOT not in sys.path:
        sys.path.insert(0, COSYVOICE_ROOT)
    if os.path.isdir(matcha_path) and matcha_path not in sys.path:
        sys.path.insert(0, matcha_path)

    from cosyvoice.cli.cosyvoice import AutoModel
    tts = AutoModel(model_dir=COSYVOICE_MODEL)

    # 打印可用说话人
    spks = tts.list_available_spks()
    print(f"[初始化] CosyVoice 加载完成，可用说话人: {spks}")
    return tts


def init_llm():
    """初始化 Ollama LLM 客户端"""
    print(f"[初始化] 连接 Ollama ({OLLAMA_MODEL})...")
    client = OpenAI(base_url=OLLAMA_BASE_URL, api_key="ollama")
    print("[初始化] Ollama 连接就绪")
    return client


def record_callback(indata, frames, time_info, status):
    """录音回调"""
    if is_recording:
        with lock:
            audio_chunks.append(indata.copy())


def speech_to_text(stt_model, audio_data):
    """语音转文字"""
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    sf.write(tmp.name, audio_data, SAMPLE_RATE)
    tmp.close()

    try:
        result = stt_model.generate(input=tmp.name)
        text = result[0]["text"] if result else ""
        for tag in []:
            text = text.replace(tag, "")
        return text.strip()
    finally:
        os.unlink(tmp.name)


def chat_with_llm(llm_client, user_text, history):
    """调用本地 LLM 生成回答"""
    history.append({"role": "user", "content": user_text})

    messages = [{"role": "system", "content": "你是一个友好的中文语音助手，回答简洁明了。"}]
    messages.extend(history[-20:])

    response = llm_client.chat.completions.create(
        model=OLLAMA_MODEL,
        messages=messages,
    )
    reply = response.choices[0].message.content
    history.append({"role": "assistant", "content": reply})
    return reply


def text_to_speech_and_play(tts_model, text):
    """文字转语音并播放"""
    output_audio = None
    for chunk in tts_model.inference_sft(text, TTS_SPEAKER, stream=False):
        piece = chunk["tts_speech"].numpy()
        if output_audio is None:
            output_audio = piece
        else:
            output_audio = np.concatenate([output_audio, piece])

    if output_audio is not None:
        sd.play(output_audio.flatten(), samplerate=tts_model.sample_rate)
        sd.wait()


def main():
    print("=" * 50)
    print("  本地语音对话系统")
    print("  按住空格键说话，松开后等待回复")
    print("  按 ESC 退出")
    print("=" * 50)
    print()

    # 初始化各模块
    stt_model = init_stt()
    tts_model = init_tts()
    llm_client = init_llm()
    history = []

    print("\n[就绪] 按住空格键开始说话...\n")

    stream = sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=CHANNELS,
        dtype="int16",
        callback=record_callback,
    )
    stream.start()

    global is_recording, audio_chunks

    def on_press(key):
        global is_recording, audio_chunks
        if key == keyboard.Key.space and not is_recording:
            with lock:
                audio_chunks = []
            is_recording = True
            print("🎤 录音中...")

    def on_release(key):
        global is_recording
        if key == keyboard.Key.space and is_recording:
            is_recording = False
            print("⏹  录音结束，处理中...")

            with lock:
                if not audio_chunks:
                    print("[提示] 没有录到声音\n")
                    return
                audio_data = np.concatenate(audio_chunks, axis=0)

            print("📝 语音识别中...")
            user_text = speech_to_text(stt_model, audio_data)
            if not user_text:
                print("[提示] 没有识别到有效语音\n")
                return
            print(f"👤 你说: {user_text}")

            print("🤖 思考中...")
            reply = chat_with_llm(llm_client, user_text, history)
            print(f"🤖 回答: {reply}")

            print("🔊 语音合成播放中...")
            text_to_speech_and_play(tts_model, reply)
            print()
            print("[就绪] 按住空格键继续说话...\n")

        if key == keyboard.Key.esc:
            print("\n👋 再见！")
            stream.stop()
            stream.close()
            return False

    with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
        listener.join()


if __name__ == "__main__":
    main()

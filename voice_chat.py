"""
本地语音对话系统 Demo
STT: SenseVoice (FunASR)
LLM: Ollama (DeepSeek 本地模型)
TTS: CosyVoice 2
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
OLLAMA_MODEL = "deepseek-r1:1.5b"
COSYVOICE_MODEL = "iic/CosyVoice-300M-SFT"
SENSEVOICE_MODEL = "iic/SenseVoiceSmall"
TTS_SPEAKER = "中文女"  # CosyVoice 2 内置说话人

# ============ 全局状态 ============
is_recording = False
audio_chunks = []
lock = threading.Lock()


def init_stt():
    """初始化 SenseVoice STT 模型"""
    print("[初始化] 加载 SenseVoice 模型...")
    from funasr import AutoModel
    model = AutoModel(model=SENSEVOICE_MODEL, trust_remote_code=True)
    print("[初始化] SenseVoice 加载完成")
    return model


def init_tts():
    """初始化 CosyVoice TTS 模型"""
    print("[初始化] 加载 CosyVoice 模型...")
    try:
        from cosyvoice import CosyVoice2
        tts = CosyVoice2(COSYVOICE_MODEL, load_jit=False, load_trt=False)
        print("[初始化] CosyVoice 2 加载完成")
    except ImportError:
        from cosyvoice.cli.cosyvoice import CosyVoice
        tts = CosyVoice(COSYVOICE_MODEL)
        print("[初始化] CosyVoice (v1) 加载完成")
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
    # 保存临时 wav 文件
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    sf.write(tmp.name, audio_data, SAMPLE_RATE)
    tmp.close()

    try:
        result = stt_model.generate(input=tmp.name)
        text = result[0]["text"] if result else ""
        # SenseVoice 输出可能带语言/情感标签，清理一下
        for tag in ["<|zh|>", "<|en|>", "<|yue|>", "<|ja|>", "<|ko|>",
                     "<|nospeech|>", "<|HAPPY|>", "<|SAD|>", "<|ANGRY|>",
                     "<|NEUTRAL|>", "<|BGM|>", "<|Speech|>", "<|Applause|>",
                     "<|Laughter|>", "<|NOISE|>", "<|woitn|>", "<|EMO_UNKNOWN|>"]:
            text = text.replace(tag, "")
        return text.strip()
    finally:
        os.unlink(tmp.name)


def chat_with_llm(llm_client, user_text, history):
    """调用本地 LLM 生成回答"""
    history.append({"role": "user", "content": user_text})

    # 只保留最近 10 轮对话
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
    # CosyVoice 2 合成
    output_audio = None
    for chunk in tts_model.inference_sft(text, TTS_SPEAKER):
        piece = chunk["tts_speech"].numpy()
        if output_audio is None:
            output_audio = piece
        else:
            output_audio = np.concatenate([output_audio, piece])

    if output_audio is not None:
        # CosyVoice 2 输出采样率通常为 22050
        sd.play(output_audio.flatten(), samplerate=22050)
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

    # 启动录音流（持续运行，通过 is_recording 控制是否采集）
    stream = sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=CHANNELS,
        dtype="int16",
        callback=record_callback,
    )
    stream.start()

    # 键盘监听
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

            # 拼接音频
            with lock:
                if not audio_chunks:
                    print("[提示] 没有录到声音\n")
                    return
                audio_data = np.concatenate(audio_chunks, axis=0)

            # STT
            print("📝 语音识别中...")
            user_text = speech_to_text(stt_model, audio_data)
            if not user_text:
                print("[提示] 没有识别到有效语音\n")
                return
            print(f"👤 你说: {user_text}")

            # LLM
            print("🤖 思考中...")
            reply = chat_with_llm(llm_client, user_text, history)
            print(f"🤖 回答: {reply}")

            # TTS + 播放
            print("🔊 语音合成播放中...")
            text_to_speech_and_play(tts_model, reply)
            print()
            print("[就绪] 按住空格键继续说话...\n")

        if key == keyboard.Key.esc:
            print("\n👋 再见！")
            stream.stop()
            stream.close()
            return False  # 停止监听

    with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
        listener.join()


if __name__ == "__main__":
    main()

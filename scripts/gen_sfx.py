#!/usr/bin/env python3
"""打磨-139a 程序合成短音效 (零素材零许可风险, 兜底路线优先于 Freesound 抓取).

生成 6 个古风短音效到 assets/sfx/ (44.1kHz 16bit 单声道 WAV, 每个 <=0.9s):
  break_win.wav    突破成功 — 五声上行两音 (徵→宫) + 磬式泛音, 短促上扬
  break_fail.wav   突破失败 — 低沉两音下坠 + 少量噪声, 压抑
  achieve.wav      成就解锁 — 三音五声上行 (宫→徵→高宫) 磬声
  tower_win.wav    塔胜利   — 鼓点 (低频脉冲) + 上扬短音
  new_record.wav   新纪录   — 高亢双叮 (宫→商 高八度)
  onekey.wav       一键系列 — 轻木扣一声 (短促中性)

全部确定性: 无随机源 (噪声用固定 LCG 种子), 重跑输出逐字节一致。
许可: 程序合成, 无第三方素材, 无需署名 (CREDITS.md 备注)。
"""
import array
import math
import os
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sfx")


def _lcg(seed: int):
    """固定种子 LCG, 确定性伪噪声."""
    s = int(seed) & 0x7FFFFFFF
    while True:
        s = (s * 48271) % 0x7FFFFFFF
        yield (s / 0x7FFFFFFF) * 2.0 - 1.0


def _tone(freq: float, dur: float, vol=0.5, decay=6.0, partials=(1.0,), delay_ms=0.0) -> list:
    """正弦波 (partials = 各泛音幅值, 频率 = 基频 x k), 前置 delay_ms 静音."""
    off = int(delay_ms / 1000.0 * RATE)
    n = int(dur * RATE)
    env = [math.exp(-(i / RATE) * decay) for i in range(n)]
    body = [0.0] * n
    for k in range(len(partials)):
        amp = partials[k]
        f = freq * (k + 1)
        for i in range(n):
            body[i] += amp * math.sin(2.0 * math.pi * f * i / RATE)
    for i in range(n):
        body[i] *= env[i] * vol
    return [0.0] * off + body


def _mix(*parts) -> list:
    """按采样位置叠加."""
    total = max(len(p) for p in parts)
    out = [0.0] * total
    for p in parts:
        for i, v in enumerate(p):
            out[i] += v
    return out


def _noise(dur: float, vol=0.15, decay=20.0, seed=7, delay_ms=0.0) -> list:
    off = int(delay_ms / 1000.0 * RATE)
    n = int(dur * RATE)
    rng = _lcg(seed)
    body = [next(rng) * math.exp(-(i / RATE) * decay) * vol for i in range(n)]
    return [0.0] * off + body


def _clip(samples: list) -> list:
    return [max(-1.0, min(1.0, v)) for v in samples]


def _write(path: str, samples: list) -> float:
    a = array.array("h", (int(v * 32767) for v in _clip(samples)))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(a.tobytes())
    return len(samples) / RATE


# 五声音阶 (G 宫系统小调, 更古朴): G 196 / A 220 / C 262 / D 294 / E 330
D2, G2, E2, HIGH_G = 294.0, 392.0, 330.0, 523.3

# 1 突破成功: 徵(330) -> 高宫(392) 上行 + 磬泛音
s = _mix(_tone(E2, 0.45, 0.42, 8.0, (1.0, 0.3)),
         _tone(G2, 0.6, 0.45, 7.0, (1.0, 0.35, 0.12), 140.0))
_write(os.path.join(OUT, "break_win.wav"), s)

# 2 突破失败: 低沉 294->147 下坠 + 噪声
s = _mix(_tone(294.0, 0.5, 0.4, 6.0, (1.0, 0.5)),
         _tone(147.0, 0.55, 0.38, 5.0, (1.0, 0.4), 160.0),
         _noise(0.35, 0.1, 18.0, 11.0, 320.0))
_write(os.path.join(OUT, "break_fail.wav"), s)

# 3 成就解锁: 宫(392)->徵(330 换向, 用 D 294)->高宫(523) 三音磬声
s = _mix(_tone(G2, 0.35, 0.4, 9.0, (1.0, 0.3)),
         _tone(294.0, 0.35, 0.4, 9.0, (1.0, 0.3), 130.0),
         _tone(HIGH_G, 0.7, 0.45, 6.5, (1.0, 0.35, 0.1), 260.0))
_write(os.path.join(OUT, "achieve.wav"), s)

# 4 塔胜利: 低频鼓点脉冲 + 上扬短音
s = _mix(_tone(82.0, 0.25, 0.5, 14.0, (1.0, 0.6)),
         _tone(164.0, 0.18, 0.35, 16.0, (1.0,), 40.0),
         _tone(G2, 0.5, 0.35, 7.0, (1.0, 0.3), 180.0))
_write(os.path.join(OUT, "tower_win.wav"), s)

# 5 新纪录: 高亢双叮 (高八度 784->880)
s = _mix(_tone(784.0, 0.4, 0.4, 8.0, (1.0, 0.25)),
         _tone(880.0, 0.55, 0.42, 7.0, (1.0, 0.25), 150.0))
_write(os.path.join(OUT, "new_record.wav"), s)

# 6 一键系列: 轻木扣一声 (高频短促)
s = _tone(2100.0, 0.06, 0.3, 40.0, (1.0, 0.4))
_write(os.path.join(OUT, "onekey.wav"), s)

print("SFX GEN OK: 6 文件 @ assets/sfx/ (确定性合成, 无随机源)")

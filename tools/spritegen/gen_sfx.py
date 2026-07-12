"""Procedurally synthesized SFX (square/saw/noise, 22050 Hz 16-bit mono WAV)."""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sfx")


def env(i, n, a=0.01, r=0.6):
    t = i / n
    if t < a:
        return t / a
    return max(0.0, 1.0 - (t - a) / max(r, 1e-6))


def synth(name, dur, gen, vol=0.5):
    n = int(SR * dur)
    frames = bytearray()
    for i in range(n):
        s = max(-1.0, min(1.0, gen(i / SR, i, n) * env(i, n) * vol))
        frames += struct.pack("<h", int(s * 32767))
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))
    print("wrote", name + ".wav")


def square(f, t):
    return 1.0 if math.sin(2 * math.pi * f * t) > 0 else -1.0


def saw(f, t):
    return 2.0 * ((f * t) % 1.0) - 1.0


rng = random.Random(7)


def main():
    synth("shoot", 0.08, lambda t, i, n: square(880 - 4400 * t, t), 0.25)
    synth("hurt", 0.18, lambda t, i, n: rng.uniform(-1, 1) * 0.7 + saw(120, t) * 0.5, 0.5)
    synth("enemy_death", 0.25, lambda t, i, n: saw(300 - 800 * t if 300 - 800 * t > 60 else 60, t), 0.4)
    synth("door", 0.2, lambda t, i, n: square(330 + 660 * t, t), 0.3)
    synth("pickup", 0.16, lambda t, i, n: square([660, 880, 1320][min(2, int(t / 0.055))], t), 0.3)
    synth("item", 0.45, lambda t, i, n: math.sin(2 * math.pi * 523 * t) + 0.6 * math.sin(2 * math.pi * 784 * t), 0.35)
    synth("roar", 0.8, lambda t, i, n: rng.uniform(-1, 1) * 0.5 + saw(70 + 30 * math.sin(12 * t), t) * 0.8, 0.6)


if __name__ == "__main__":
    main()

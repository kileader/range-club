"""Generate Range Club's small, original sound effects with the Python stdlib."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def write_sound(name: str, duration: float, synth) -> None:
    frames = bytearray()
    noise = random.Random(3909)
    for i in range(round(duration * SAMPLE_RATE)):
        time = i / SAMPLE_RATE
        value = max(-0.9, min(0.9, synth(time, duration, noise)))
        frames.extend(struct.pack("<h", round(value * 32767)))
    with wave.open(str(OUT / name), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(SAMPLE_RATE)
        audio.writeframes(frames)


def release(t: float, duration: float, noise: random.Random) -> float:
    envelope = math.sin(math.pi * t / duration) ** 0.7
    chirp = math.sin(2 * math.pi * (780 * t - 1800 * t * t))
    return envelope * (0.24 * chirp + 0.12 * noise.uniform(-1, 1))


def hit(t: float, _duration: float, noise: random.Random) -> float:
    envelope = (1 - math.exp(-t * 180)) * math.exp(-t * 15)
    ring = math.sin(2 * math.pi * 660 * t) + 0.35 * math.sin(2 * math.pi * 1320 * t)
    return 0.43 * envelope * ring + 0.045 * math.exp(-t * 80) * noise.uniform(-1, 1)


def miss(t: float, _duration: float, noise: random.Random) -> float:
    envelope = (1 - math.exp(-t * 150)) * math.exp(-t * 20)
    thud = math.sin(2 * math.pi * (150 * t - 170 * t * t))
    return envelope * (0.36 * thud + 0.11 * noise.uniform(-1, 1))


def notes(t: float, pitches: tuple[int, ...], step: float, decay: float) -> float:
    value = 0.0
    for index, pitch in enumerate(pitches):
        elapsed = t - index * step
        if elapsed < 0:
            continue
        envelope = (1 - math.exp(-elapsed * 90)) * math.exp(-elapsed * decay)
        value += envelope * (
            math.sin(2 * math.pi * pitch * elapsed)
            + 0.22 * math.sin(2 * math.pi * pitch * 2 * elapsed)
        )
    return value * 0.19


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    write_sound("release.wav", 0.14, release)
    write_sound("hit.wav", 0.24, hit)
    write_sound("miss.wav", 0.20, miss)
    write_sound("clear.wav", 0.60, lambda t, _d, _n: notes(t, (523, 659, 784, 1047), 0.09, 10))
    write_sound("bust.wav", 0.48, lambda t, _d, _n: notes(t, (440, 330, 220), 0.11, 13))
    write_sound("fail.wav", 0.42, lambda t, _d, _n: notes(t, (392, 294), 0.12, 14))


if __name__ == "__main__":
    main()

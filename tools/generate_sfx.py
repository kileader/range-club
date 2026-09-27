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


def draw(t: float, duration: float, noise: random.Random) -> float:
    envelope = math.sin(math.pi * t / duration) ** 0.6
    creak = math.sin(2 * math.pi * (115 * t + 110 * t * t))
    grain = 0.5 + 0.5 * math.sin(2 * math.pi * 31 * t)
    return envelope * (0.24 * creak * grain + 0.035 * noise.uniform(-1, 1))


def ready(t: float, _duration: float, _noise: random.Random) -> float:
    envelope = (1 - math.exp(-t * 170)) * math.exp(-t * 30)
    return 0.25 * envelope * (math.sin(2 * math.pi * 880 * t) + 0.3 * math.sin(2 * math.pi * 1320 * t))


def release(t: float, duration: float, noise: random.Random) -> float:
    # A short string snap, damped bow-body resonance, then air through the flight.
    pluck = math.exp(-t * 28) * (
        0.3 * math.sin(2 * math.pi * 145 * t)
        + 0.16 * math.sin(2 * math.pi * 290 * t)
        + 0.08 * math.sin(2 * math.pi * 720 * t)
    )
    snap = 0.3 * math.exp(-t * 180) * noise.uniform(-1, 1)
    air = 0.09 * math.sin(math.pi * t / duration) * noise.uniform(-1, 1)
    return pluck + snap + air


def hit(t: float, _duration: float, noise: random.Random) -> float:
    envelope = (1 - math.exp(-t * 500)) * math.exp(-t * 23)
    thud = 0.48 * math.sin(2 * math.pi * 105 * t) + 0.16 * math.sin(2 * math.pi * 235 * t)
    crack = 0.28 * math.exp(-t * 95) * noise.uniform(-1, 1)
    shaft = 0.1 * math.exp(-t * 14) * math.sin(2 * math.pi * 540 * t)
    return envelope * thud + crack + shaft


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
    write_sound("draw.wav", 0.52, draw)
    write_sound("ready.wav", 0.15, ready)
    write_sound("release.wav", 0.22, release)
    write_sound("hit.wav", 0.24, hit)
    write_sound("miss.wav", 0.20, miss)
    write_sound("clear.wav", 0.60, lambda t, _d, _n: notes(t, (523, 659, 784, 1047), 0.09, 10))
    write_sound("bust.wav", 0.48, lambda t, _d, _n: notes(t, (440, 330, 220), 0.11, 13))
    write_sound("fail.wav", 0.42, lambda t, _d, _n: notes(t, (392, 294), 0.12, 14))


if __name__ == "__main__":
    main()

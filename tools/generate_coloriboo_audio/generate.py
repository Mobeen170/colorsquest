#!/usr/bin/env python3
"""Generate Coloriboo's original, dependency-free WAV starter pack.

The generator intentionally uses only Python's standard library. Every sound
is built from simple oscillators and deterministic filtered noise; no samples,
downloads, or third-party material are used.
"""

from __future__ import annotations

import math
import struct
import wave
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


SAMPLE_RATE = 44_100
ROOT = Path(__file__).resolve().parents[2]
SFX_DIR = ROOT / "assets" / "audio" / "sfx"
MUSIC_DIR = ROOT / "assets" / "audio" / "music"


def clamp(value: float) -> float:
    return max(-0.96, min(0.96, value))


def fade_edges(t: float, duration: float, edge: float = 0.008) -> float:
    return min(1.0, t / edge, (duration - t) / edge)


def decay_envelope(t: float, duration: float, attack: float = 0.012) -> float:
    if t < 0.0 or t >= duration:
        return 0.0
    if t < attack:
        return math.sin((t / attack) * math.pi / 2.0) ** 2
    progress = (t - attack) / max(0.001, duration - attack)
    return (1.0 - progress) ** 2.4


def sine(frequency: float, t: float, phase: float = 0.0) -> float:
    return math.sin(math.tau * frequency * t + phase)


def bell(t: float, frequency: float, duration: float, amplitude: float) -> float:
    envelope = decay_envelope(t, duration)
    return amplitude * envelope * (
        0.78 * sine(frequency, t)
        + 0.16 * sine(frequency * 2.01, t, 0.2)
        + 0.06 * sine(frequency * 3.98, t, 0.5)
    )


def soft_tone(
    t: float,
    frequency: float,
    duration: float,
    amplitude: float,
    end_frequency: float | None = None,
) -> float:
    if t < 0.0 or t >= duration:
        return 0.0
    envelope = decay_envelope(t, duration, attack=0.018)
    if end_frequency is None:
        phase = math.tau * frequency * t
    else:
        sweep = (end_frequency - frequency) / duration
        phase = math.tau * (frequency * t + 0.5 * sweep * t * t)
    return amplitude * envelope * (
        0.90 * math.sin(phase) + 0.10 * math.sin(2.0 * phase)
    )


def deterministic_noise(index: int, seed: int) -> float:
    value = (index * 1_103_515_245 + seed * 12_345) & 0x7FFF_FFFF
    return (value / 1_073_741_823.5) - 1.0


@dataclass(frozen=True)
class Note:
    start: float
    frequency: float
    duration: float
    amplitude: float
    pan: float = 0.0


def notes_sampler(notes: tuple[Note, ...]) -> Callable[[float, int], tuple[float, float]]:
    def sample(t: float, _: int) -> tuple[float, float]:
        left = 0.0
        right = 0.0
        for note in notes:
            value = bell(
                t - note.start,
                note.frequency,
                note.duration,
                note.amplitude,
            )
            left += value * (1.0 - max(0.0, note.pan) * 0.35)
            right += value * (1.0 + min(0.0, note.pan) * 0.35)
        return left, right

    return sample


def write_wav(
    path: Path,
    duration: float,
    sampler: Callable[[float, int], tuple[float, float]],
    master: float = 1.0,
    edge_fade: bool = True,
) -> None:
    frame_count = round(duration * SAMPLE_RATE)
    frames = bytearray()
    for index in range(frame_count):
        t = index / SAMPLE_RATE
        left, right = sampler(t, index)
        edge = fade_edges(t, duration) if edge_fade else 1.0
        left_sample = round(clamp(left * master * edge) * 32_767)
        right_sample = round(clamp(right * master * edge) * 32_767)
        frames.extend(struct.pack("<hh", left_sample, right_sample))

    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(frames)


def airy_pop(t: float, index: int) -> tuple[float, float]:
    air = deterministic_noise(index, 17) * 0.16 * math.exp(-t * 23.0)
    body = soft_tone(t, 310.0, 0.26, 0.38, 155.0)
    return body + air, body + air * 0.82


def soft_bubble(t: float, _: int) -> tuple[float, float]:
    value = soft_tone(t, 245.0, 0.25, 0.27, 195.0)
    return value, value


def button_plip(t: float, _: int) -> tuple[float, float]:
    value = soft_tone(t, 620.0, 0.17, 0.25, 470.0)
    return value * 0.94, value


def try_again(t: float, _: int) -> tuple[float, float]:
    first = soft_tone(t, 294.0, 0.33, 0.23, 238.0)
    second = soft_tone(t - 0.19, 262.0, 0.28, 0.15, 220.0)
    return first + second, first + second


def sparkle(t: float, index: int) -> tuple[float, float]:
    shimmer = deterministic_noise(index, 41) * 0.018 * decay_envelope(t, 0.68)
    sweep = soft_tone(t, 720.0, 0.63, 0.10, 1_560.0)
    bells = notes_sampler(
        (
            Note(0.08, 1_047.0, 0.52, 0.16, -0.5),
            Note(0.21, 1_319.0, 0.43, 0.13, 0.5),
        )
    )(t, index)
    return sweep + bells[0] + shimmer, sweep + bells[1] - shimmer


def mixing_merge(t: float, index: int) -> tuple[float, float]:
    sweep = soft_tone(t, 196.0, 0.86, 0.24, 523.0)
    drop_a = soft_tone(t - 0.10, 360.0, 0.18, 0.09, 250.0)
    drop_b = soft_tone(t - 0.32, 410.0, 0.20, 0.08, 285.0)
    air = deterministic_noise(index, 73) * 0.012 * decay_envelope(t, 0.84)
    return sweep + drop_a + air, sweep + drop_b - air


def boo_magic(t: float, index: int) -> tuple[float, float]:
    sweep = soft_tone(t, 280.0, 0.95, 0.18, 900.0)
    bells = notes_sampler(
        (
            Note(0.18, 659.3, 0.66, 0.15, -0.4),
            Note(0.38, 880.0, 0.52, 0.13, 0.4),
        )
    )(t, index)
    return sweep + bells[0], sweep + bells[1]


def music_sampler(duration: float) -> Callable[[float, int], tuple[float, float]]:
    # Frequencies are quantised to whole cycles per loop, making the quiet pad
    # mathematically continuous at the seam.
    def loop_frequency(frequency: float) -> float:
        return round(frequency * duration) / duration

    melody = (
        Note(0.80, 523.25, 2.25, 0.105, -0.45),
        Note(2.35, 659.25, 2.00, 0.085, 0.30),
        Note(4.10, 783.99, 2.20, 0.090, 0.50),
        Note(6.05, 659.25, 2.15, 0.078, -0.20),
        Note(8.45, 587.33, 2.25, 0.088, -0.55),
        Note(10.15, 698.46, 2.10, 0.078, 0.35),
        Note(12.15, 880.00, 2.35, 0.086, 0.55),
        Note(14.30, 783.99, 2.10, 0.072, -0.30),
        Note(16.65, 659.25, 2.25, 0.084, -0.45),
        Note(18.30, 587.33, 2.20, 0.075, 0.25),
        Note(20.20, 523.25, 2.35, 0.090, 0.45),
    )
    melody_sample = notes_sampler(melody)
    pad_frequencies = tuple(
        loop_frequency(frequency) for frequency in (130.81, 196.00, 261.63)
    )

    def sample(t: float, index: int) -> tuple[float, float]:
        pulse = 0.78 + 0.22 * math.cos(math.tau * t / duration)
        pad = sum(sine(frequency, t) for frequency in pad_frequencies) / 3.0
        pad *= 0.030 * pulse
        left, right = melody_sample(t, index)
        return pad + left, pad + right

    return sample


def generate() -> None:
    effects: tuple[
        tuple[str, float, Callable[[float, int], tuple[float, float]], float], ...
    ] = (
        ("button_tap.wav", 0.18, button_plip, 0.90),
        ("bubble_pop.wav", 0.30, airy_pop, 0.92),
        ("bubble_soft.wav", 0.27, soft_bubble, 0.88),
        (
            "correct_chime.wav",
            0.78,
            notes_sampler(
                (
                    Note(0.00, 523.25, 0.60, 0.23, -0.35),
                    Note(0.15, 659.25, 0.58, 0.21, 0.15),
                    Note(0.30, 783.99, 0.47, 0.19, 0.45),
                )
            ),
            0.90,
        ),
        ("try_again.wav", 0.50, try_again, 0.86),
        ("sparkle.wav", 0.70, sparkle, 0.90),
        ("mixing_merge.wav", 0.90, mixing_merge, 0.90),
        (
            "activity_transition.wav",
            0.60,
            notes_sampler(
                (
                    Note(0.00, 440.00, 0.48, 0.16, -0.40),
                    Note(0.11, 554.37, 0.44, 0.15, 0.00),
                    Note(0.22, 659.25, 0.38, 0.14, 0.40),
                )
            ),
            0.88,
        ),
        ("boo_magic.wav", 0.98, boo_magic, 0.88),
        (
            "loading_twinkle.wav",
            0.58,
            notes_sampler(
                (
                    Note(0.00, 783.99, 0.52, 0.11, -0.30),
                    Note(0.16, 1_046.50, 0.40, 0.09, 0.35),
                )
            ),
            0.82,
        ),
        (
            "celebration.wav",
            1.42,
            notes_sampler(
                (
                    Note(0.00, 392.00, 0.72, 0.19, -0.45),
                    Note(0.16, 523.25, 0.75, 0.19, -0.10),
                    Note(0.34, 659.25, 0.80, 0.18, 0.25),
                    Note(0.55, 783.99, 0.82, 0.17, 0.48),
                )
            ),
            0.92,
        ),
        (
            "big_celebration.wav",
            2.20,
            notes_sampler(
                (
                    Note(0.00, 261.63, 0.95, 0.18, -0.55),
                    Note(0.14, 392.00, 0.95, 0.18, -0.25),
                    Note(0.30, 523.25, 1.10, 0.19, 0.10),
                    Note(0.50, 659.25, 1.10, 0.18, 0.38),
                    Note(0.72, 783.99, 1.20, 0.17, 0.55),
                    Note(1.04, 1_046.50, 1.12, 0.14, 0.05),
                )
            ),
            0.94,
        ),
        (
            "finish_session.wav",
            1.45,
            notes_sampler(
                (
                    Note(0.00, 659.25, 0.88, 0.18, 0.35),
                    Note(0.25, 523.25, 0.92, 0.18, 0.00),
                    Note(0.52, 392.00, 0.90, 0.17, -0.35),
                )
            ),
            0.90,
        ),
    )

    for filename, duration, sampler, master in effects:
        write_wav(SFX_DIR / filename, duration, sampler, master=master)
        print(f"generated {filename:25} {duration:5.2f}s")

    music_duration = 24.0
    write_wav(
        MUSIC_DIR / "coloriboo_pop_loop.wav",
        music_duration,
        music_sampler(music_duration),
        master=0.92,
        edge_fade=False,
    )
    print(f"generated {'coloriboo_pop_loop.wav':25} {music_duration:5.2f}s")


if __name__ == "__main__":
    generate()

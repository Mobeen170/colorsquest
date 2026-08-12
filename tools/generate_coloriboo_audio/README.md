# Coloriboo audio generator

Run `python3 tools/generate_coloriboo_audio/generate.py` from anywhere to
rebuild Coloriboo's original WAV sound pack. It uses only Python's standard
library and deterministic synthesis; it does not download or sample external
audio.

Output is stereo, 16-bit PCM at 44.1 kHz. The 24-second twilight track uses
loop-period-quantised pad frequencies so the end joins the beginning cleanly.

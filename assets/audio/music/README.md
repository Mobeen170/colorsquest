# Coloriboo music

`coloriboo_pop_loop.wav` is the approved 24-second production loop. It is
stereo, 16-bit PCM at 44.1 kHz, normalized to approximately 72% peak, and
designed to join cleanly at its loop boundary. It is the only music file
declared in `pubspec.yaml` and therefore the only loop packaged at runtime.

`coloriboo_twilight_loop.wav` is retained as an unused legacy source file for
the existing audio-generation workflow; it is deliberately not bundled.

Production music remains optional at runtime. It starts only after explicit
world entry and ducks while Boo speaks.

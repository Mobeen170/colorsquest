# Sound effects

Drop properly licensed `.mp3` files here using these exact names.

| File | Used for |
| --- | --- |
| `bubble_pop.mp3` | popping a colour bubble |
| `bubble_soft.mp3` | a gentle wrong-tap wobble (never a buzzer) |
| `sparkle.mp3` | a colour being revealed or mixed |
| `correct.mp3` | small correct-answer chime |
| `try_again.mp3` | soft encouraging retry |
| `drag_snap.mp3` | a dragged bubble snapping into place |
| `celebration.mp3` | the occasional big celebration |

Every file is **optional**. `AudioService` checks for each one at startup and
silently skips any that are missing, so the app always runs.

Suggested sources: Pixabay, Mixkit. Keep each clip short and quiet.

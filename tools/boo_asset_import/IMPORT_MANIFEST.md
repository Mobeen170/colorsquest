# Boo Asset Import Manifest

Imported on 2026-08-12 from the temporary `to_put_in_use/` folder.

Audit result: 20 source PNGs, 20 unique accepted PNGs, 0 exact duplicates,
0 rejected files. Every source was already an 8-bit RGBA PNG with genuine
edge-connected transparency. No background cleanup, masking, cropping, or
pixel resampling was performed. Production files are byte-identical copies of
their accepted sources.

| Original file | Final production file | Role | Dimensions | Background cleanup | Status |
|---|---|---|---:|---|---|
| `ChatGPT Image Aug 12, 2026, 04_27_43 PM (1).png` | `assets/mascot/boo/colors/boo_red.png` | Neutral red teaching family; Boo's Magic and successful red result | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_27_43 PM (2).png` | `assets/mascot/boo/colors/boo_orange.png` | Neutral orange teaching family; Boo's Magic and orange-family result | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_27_45 PM (3).png` | `assets/mascot/boo/colors/boo_yellow.png` | Neutral yellow teaching family; Boo's Magic and yellow-family result | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_27_47 PM (4).png` | `assets/mascot/boo/colors/boo_green.png` | Neutral green teaching family; Boo's Magic and green-family result | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_27_48 PM (5).png` | `assets/mascot/boo/core/boo_idle_blue.png` | Canonical blue brand, idle, welcome, speaking, and production fallback | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_27_49 PM (6).png` | `assets/mascot/boo/colors/boo_purple.png` | Neutral purple teaching family; Boo's Magic and purple-family result | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_27_50 PM (7).png` | `assets/mascot/boo/colors/boo_pink.png` | Neutral pink teaching family; Boo's Magic and pink-family result | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_27_51 PM (8).png` | `assets/mascot/boo/colors/boo_brown.png` | Neutral brown teaching family; Boo's Magic and earth-family result | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_27_52 PM (9).png` | `assets/mascot/boo/colors/boo_white.png` | Neutral white/pearl teaching family; Boo's Magic and light-neutral result | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_27_53 PM (10).png` | `assets/mascot/boo/colors/boo_black.png` | Neutral black teaching family; Boo's Magic and dark-neutral result | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_02 PM (1).png` | `assets/mascot/boo/states/boo_correct_red.png` | Correct answer, ordinary celebration, and positive success | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_02 PM (2).png` | `assets/mascot/boo/states/boo_try_again_orange.png` | Gentle miss, try-again audio, and supportive retry | 1024×1536 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_03 PM (3).png` | `assets/mascot/boo/states/boo_loading_yellow.png` | World-entry loading and loading-twinkle moments | 1254×1254 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_04 PM (4).png` | `assets/mascot/boo/states/boo_waiting_green.png` | Calm waiting/listening and minimal parent settings companion | 1024×1536 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_05 PM (5).png` | `assets/mascot/boo/states/boo_alert_blue.png` | New-activity attention cue and loading discovery phase | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_06 PM (6).png` | `assets/mascot/boo/states/boo_thinking_purple.png` | Odd One Out, Light to Dark, reasoning, and thinking time | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_07 PM (7).png` | `assets/mascot/boo/states/boo_encouraging_pink.png` | Friendly encouragement, empty-session warmth, and goodbye | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_08 PM (8).png` | `assets/mascot/boo/states/boo_pointing_brown.png` | Hint guidance and Boo's Play Compass | 1536×1024 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_09 PM (9).png` | `assets/mascot/boo/special/boo_magic_pearl.png` | Mixing, magical reveal, loading transition, and Wonder Sky/end discovery | 1024×1536 | No—original alpha preserved | Used |
| `ChatGPT Image Aug 12, 2026, 04_31_09 PM (10).png` | `assets/mascot/boo/special/boo_big_celebration_black.png` | Rare five-correct milestone and large session achievement | 1536×1024 | No—original alpha preserved | Used |

## Duplicate and quality decision record

- Exact SHA-256 duplicate groups: none.
- The ten neutral color-family images intentionally share a pose but teach
  different colors and are not duplicates.
- Same-color neutral/state pairs have distinct expressions or poses and
  separate interaction roles.
- No image was rejected: no broken decode, hard crop, matte background,
  destructive artifact, or materially lower-quality duplicate was found.
- Low-alpha aura pixels that reach an edge on a few exports are intentional
  glow/translucency. They were retained rather than aggressively thresholded.

Catalog paths, production file counts, hashes, pubspec registration,
formatting, static analysis, and reference checks completed successfully. The
20 verified source copies remain in `to_put_in_use/` because this environment
declined the final deletion operation; they are staging only and are not
registered in `pubspec.yaml` or referenced by runtime code.

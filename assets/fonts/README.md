# Font

Coloriboo currently uses the system font. Adding a rounded, chunky typeface is
the single highest-impact change left for how premium the app looks.

## What to download

Any of these, all free under the SIL Open Font License:

- **Baloo 2** — recommended. Rounded, warm, chunky, made for exactly this.
- **Fredoka** — slightly geometric, very clean.
- **Nunito** — softer and more neutral.

Download from [fonts.google.com](https://fonts.google.com) and put the `.ttf`
files in this folder. Three weights are used: regular (400), semibold (600) and
extrabold (800).

## Wiring it up

1. Add the family to `pubspec.yaml` under `flutter:`

   ```yaml
   fonts:
     - family: Baloo2
       fonts:
         - asset: assets/fonts/Baloo2-Regular.ttf
           weight: 400
         - asset: assets/fonts/Baloo2-SemiBold.ttf
           weight: 600
         - asset: assets/fonts/Baloo2-ExtraBold.ttf
           weight: 800
   ```

2. Set the name in `lib/app_theme.dart`:

   ```dart
   static const String? fontFamily = 'Baloo2';
   ```

That is the only code change needed. Every text style in the app reads from
that one value.

## Why a file rather than the google_fonts package

`google_fonts` fetches typefaces over the network the first time the app runs.
A child playing offline would see the fallback font instead, which is the wrong
trade for an app meant to work anywhere.

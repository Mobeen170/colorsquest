# Coloriboo — Development Rules

Coloriboo is a **small Flutter children's color-learning app**.
Tagline: *Pop. Play. Learn Colors!*

> Bubbles are the world. Boo is the character. Colors are the game.

## Code style

- Keep the code **beginner-readable**. Simple widgets, clear names, short files.
- Use normal Flutter/Dart before adding any package.
- Do **not** introduce Bloc, Riverpod, Provider, GetX, databases, authentication,
  backend services, repositories, or enterprise architecture unless explicitly
  requested later.
- Mobile-first responsive design is required. Use `LayoutBuilder`, `MediaQuery`,
  `Expanded`, and `SafeArea` instead of fixed pixel layouts.

## Product rules

- **Boo is the only mascot.** Do not invent additional characters.
- **Wrong answers must always be encouraging, never harsh.** Prefer "Try again!"
  over "WRONG!". This app is for children.

## Working rules

- Preserve working functionality unless the current task explicitly changes it.
- Do **not** silently redesign or remove features.
- Inspect the existing code before making major changes.
- Explain every changed file after each phase.
- **Never make Git commits automatically.** The user commits.

## After every coding task

```bash
dart format lib test
flutter analyze
flutter test
```

Fix anything your changes broke. Never hide analyzer warnings or test failures.

## Brand colors

Defined once in [lib/app_theme.dart](lib/app_theme.dart) — use `AppColors`, never
raw hex in screens.

| Name          | Hex       |
| ------------- | --------- |
| Bubble Sky    | `#EAF9FF` |
| Boo Blue      | `#58C9F5` |
| Bubble Purple | `#8B7CFF` |
| Bubble Pink   | `#FF83C6` |
| Bubble Mint   | `#6FE3BC` |
| Sunny Pop     | `#FFD965` |
| Dark Ink      | `#26324A` |
| Soft Ink      | `#64748B` |
| White         | `#FFFFFF` |

Visual personality: bubbly, joyful, encouraging, premium, clean, modern,
child-friendly.

## Naming

"Coloriboo" is currently a **display brand only**. Do not change the Dart package
name (`colorsquest`), the Android `applicationId`, the iOS bundle identifier, or
any signing configuration.

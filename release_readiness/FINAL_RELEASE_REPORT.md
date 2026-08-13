# Coloriboo Final Release Report

**Report snapshot:** 2026-08-13  
**Source version:** `1.0.0+1`  
**Current disposition:** **Technical release validation passed; external
store, signing, policy-publication, and final-device actions remain.**

This report records what is true in the current repository and what must be
completed outside source control. It does not claim that an unsigned local
build or a debug run is a production artifact.

## Product and identity record

| Item | Current authoritative value | Source |
|---|---|---|
| User-facing app name | **Coloriboo** | Android main manifest, iOS `Info.plist`, Flutter `MaterialApp` |
| Tagline | **Pop. Play. Learn Colors!** | Start screen and app documentation |
| Dart package name | `colorsquest` | `pubspec.yaml` |
| Version / build | `1.0.0` / `1` | `pubspec.yaml` (`1.0.0+1`) |
| Android application ID | `com.example.colorsquest` | `android/app/build.gradle.kts` |
| Android namespace | `com.example.colorsquest` | `android/app/build.gradle.kts` |
| Android launcher activity package | `com.example.colorsquest` | `android/app/src/main/kotlin/com/example/colorsquest/MainActivity.kt` |
| iOS app bundle ID | `com.example.colorsquest` | `ios/Runner.xcodeproj/project.pbxproj` |
| iOS test bundle ID | `com.example.colorsquest.RunnerTests` | `ios/Runner.xcodeproj/project.pbxproj` |
| iOS deployment target | `13.0` | Runner project and `ios/Podfile` |
| Supported Apple device families | iPhone and iPad (`1,2`) | Runner project |

### Frozen identifier decision

The Android and iOS identifiers look like template identifiers, but the user
explicitly instructed that `com.example.colorsquest` be preserved. **Do not
rename the Android application ID, Android namespace/package, iOS app bundle
ID, or test bundle as part of release cleanup.** Store records, App IDs,
profiles, and signing configuration must be created or selected for these exact
values. If the owner ever reverses this product decision, treat it as a
separate migration with store-history consequences—not a cleanup edit.

## Product implemented in the current tree

Coloriboo is a gentle, endless color-learning world for young children. Boo
guides five activities:

1. **Pop the Colour** — listen, look, and pop the named color.
2. **Odd One Out** — find the light that is different.
3. **Boo Changes Colour / Boo's Magic** — identify Boo's current color.
4. **Colour Mixing Lab** — drag two color bubbles together to reveal a mix.
5. **Light to Dark** — order shades from bright to dark.

The next activity is selected after a completed round without repeating the
same activity immediately. Incorrect taps are named and followed by an
encouraging retry, hint, or reveal; they do not end the session. The optional
Finish flow shows only an in-memory session summary, not a persisted score or
child profile. Music, sound effects, Boo's voice, written words, master mute,
and reduced-motion behavior are present.

## Current platform configuration

### Android

- Current audited local resolution: compile SDK 36, target SDK 36, minimum SDK
  24, NDK `28.2.13676358`, Java/Kotlin target 17.
- Android Gradle Plugin `9.0.1`, Kotlin plugin `2.3.20`, Gradle `9.1.0`.
- Main manifest display label is **Coloriboo**.
- Main manifest declares no `uses-permission` entries.
- Debug/profile manifests declare `INTERNET` only for Flutter development
  tooling and must not be distributed.
- Main manifest package visibility contains Flutter's `PROCESS_TEXT` query and
  the Android 11+ `TTS_SERVICE` query. These are queries, not permissions.
- Launcher icons and an Android adaptive icon are present.
- Branded native launch resources use approved Boo art on Coloriboo's pale-blue
  background for legacy and Android 12+ day/night launches; installed Android
  visual confirmation remains pending.
- Release Gradle configuration reads `android/key.properties` when it exists
  and never falls back to Flutter's debug signing key. No `key.properties` or
  upload keystore is present, so the current release variant has no signing
  configuration and any locally generated AAB is expected to be unsigned.

### iOS / iPadOS

- `Info.plist` display and bundle names are **Coloriboo**.
- Deployment target is 13.0 in both the Runner project and Podfile.
- iPhone supports portrait and both landscape orientations; iPad additionally
  supports portrait upside down.
- No protected-resource usage descriptions, background modes, ATS exceptions,
  or app entitlements are present in source.
- Runner has no explicit signing style or `DEVELOPMENT_TEAM` in source;
  RunnerTests uses automatic signing. Distribution signing is unconfigured.
- Audit environment: Xcode 26.3 (build 17C529), iOS SDK 26.2, with zero valid
  local code-signing identities found. Apple has required Xcode 26 / iOS 26 SDK
  or later for uploads since 2026-04-28.
- The 1024-pixel App Store icon is RGB without alpha. Device/mask appearance
  still needs a final visual check.
- The native launch storyboard uses canonical Boo artwork with `aspectFit` on
  the same pale-blue brand background. A freshly built simulator app installed,
  launched, and rendered the branded Coloriboo start screen on an iPhone 16e.

## Dependency record

| Direct runtime dependency | Constraint | Locked | Assessment |
|---|---:|---:|---|
| `cupertino_icons` | `^1.0.8` | `1.0.9` | Local icons; low privacy risk |
| `flutter_tts` | `^4.2.0` | `4.2.5` | Current at audit time; device speech service, no runtime permission |
| `flutter_soloud` | `^3.1.10` | `3.5.4` | Local audio only; framework privacy resource is injected by the app Podfile |

The current app does not call the transitive `http` package. It only asks
SoLoud to load bundled assets or generated waveforms. SoLoud can copy bundled
audio into application temporary storage; this is not personal data but can
leave roughly 10 MB of finite cache content until the OS clears it.

`flutter pub outdated` reports `flutter_soloud` 4.1.7. Version 4 includes later
native fixes but is a breaking migration, and the published package still does
not include the required iOS privacy resource. The stable 3.5.4 integration was
retained and patched at packaging level; any future major migration needs the
complete audio, platform-build, and privacy regression pass again.

## Privacy and child-safety result

Current code has no account, developer backend, analytics, ads, tracking,
attribution, crash upload, persistent child profile, in-app purchase, social
feature, camera, microphone, contacts, photos, or location feature. Gameplay
and settings remain on-device and in memory.

Boo's text-to-speech phrases are fixed app-authored learning text. The app does
not record speech. A device-selected Android speech provider can offer a
network-required voice, so public copy must not promise that every possible
voice is processed offline. See:

- `docs/PRIVACY_POLICY.md`
- `docs/STORE_DATA_SAFETY_NOTES.md`
- `release_readiness/PRIVACY_AND_DATA_SAFETY.md`

## Release blockers

### P0 — must resolve before any store upload

- [ ] **Android signing:** obtain the owner's existing upload key (or create the
      approved first-release upload key), create a local gitignored
      `android/key.properties`, and prove the AAB is signed by the expected
      certificate. An unsigned AAB built without that file is useful technical
      build evidence, but it is not a store-upload candidate.
- [ ] **Apple signing:** select the Apple Developer team, register/select the
      exact `com.example.colorsquest` App ID, and install a valid distribution
      certificate/profile. Do not change the bundle ID to work around signing.
- [x] **SoLoud Apple privacy packaging:** the clean unsigned Release product
      contains the audited
      `PrivacyInfo.xcprivacy` in the `flutter_soloud` framework with Apple
      reasons `C617.1` and `35F9.1`, no tracking, and no collected data. The
      final signed archive still needs Xcode's aggregate privacy report.
- [ ] **Public privacy policy:** replace placeholders, obtain publisher/legal
      approval, host at a stable HTTPS URL, enter it in both stores, and expose
      it from an accessible grown-up area in the app.
- [ ] **Kids parental gate:** if selecting Apple's Kids category and providing
      an external policy/support link in app, put link-outs behind a genuine
      adult-level parental gate. The current long-press-only settings entry is
      an accidental-tap guard, not evidence of an Apple-compliant adult task.
- [ ] **Final signed artifacts:** build, inspect, hash, install, and test the
      exact AAB and IPA/archive intended for upload.
- [ ] **Store declarations:** complete Google Target Audience, Families, Data
      safety, ads, app access, IARC, and Apple App Privacy, age rating, Kids age
      band, export-compliance, and content-rights forms accurately.

### P1 — required release evidence

- [ ] Complete Android 16 KB runtime testing on a 16 KB Android device or
      emulator. The technical AAB checks pass: BundleConfig reports
      `PAGE_ALIGNMENT_16K`, and all 27 ELF libraries use 16 KB or 64 KB LOAD
      alignment.
- [x] Inspect the merged **release** manifest, not only source/debug manifests.
- [ ] Generate Xcode Organizer's privacy report and inspect every embedded
      framework, entitlement, usage description, and signature.
- [ ] Test on small and normal phones, large phones, and tablets/iPads in
      supported portrait/landscape orientations.
- [ ] Test with animations disabled/reduced motion, master mute, each individual
      audio toggle, missing optional audio, offline mode, and unavailable TTS.
- [ ] Capture final store screenshots from the signed candidate.
- [ ] Confirm the correct first-release version/build number or increment it to
      a store-acceptable unused value.

### P2 — repository hygiene

- [x] The 20 verified staging PNGs in `to_put_in_use/` were byte-identical to
      the 20 production Boo assets and fully covered by the import manifest.
      After confirming no runtime or pubspec references, the staging-only
      copies were removed on 2026-08-13. Production artwork is unchanged.
- [x] Unreferenced default-Flutter Android launcher PNGs and unassigned 1×1
      iOS launch placeholders were removed; active Coloriboo launcher and
      native launch resources remain intact.

## Validation ledger — 2026-08-13 final local run

| Check | Result | Evidence / artifact |
|---|---|---|
| `flutter pub get` | **PASS** | Dependency resolution completed on 2026-08-13; lock remained stable |
| `dart format lib test` | **PASS** | 45 files checked; 0 implementation changes, then the one corrected test formatted cleanly |
| `flutter analyze` | **PASS** | `No issues found!` |
| `flutter test` | **PASS** | **163 / 163 tests passed** |
| Android release AAB | **PASS — UNSIGNED TECHNICAL ARTIFACT** | `build/app/outputs/bundle/release/app-release.aab`; 93,928,754 bytes; SHA-256 `00488695921d0e30647a57c5146c27990ab3d94b3b82433469a28aa7242b5eca` |
| Android merged release manifest | **PASS** | `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`: ID `com.example.colorsquest`, `1.0.0` / `1`, min 24, target 36, no `INTERNET` or sensitive permission |
| Android 16 KB validation | **PASS BINARY / PENDING DEVICE** | BundleConfig: `PAGE_ALIGNMENT_16K`; all 27 native libraries have ELF LOAD alignment `2**14` or `2**16`; 16 KB runtime device test pending |
| iOS simulator build / launch | **PASS** | Fresh debug simulator app built, installed, launched on iPhone 16e, and rendered the approved start screen without a runtime exception |
| iOS unsigned Release product | **PASS — NOT AN ARCHIVE/IPA** | `build/ios/iphoneos/Runner.app` (about 60 MiB); ID `com.example.colorsquest`; version/build `1.0.0` / `1`; minimum iOS 13.0; intentionally unsigned |
| iOS Release archive / IPA | **BLOCKED EXTERNALLY** | No Apple team, distribution identity, or provisioning profile is available; no `.xcarchive` or `.ipa` was created |
| Xcode privacy report | **[PENDING FINAL ARCHIVE]** | `[PENDING REPORT PATH]` |
| TestFlight install | **[PENDING FINAL ARCHIVE]** | `[PENDING BUILD / DEVICE]` |
| Physical Android smoke test | **[PENDING FINAL AAB]** | `[PENDING DEVICE / OS]` |
| Physical iPhone/iPad smoke test | **[PENDING FINAL IPA]** | `[PENDING DEVICE / OS]` |

## Artifact sign-off

Do not mark this report ready until every P0 item and validation row is
complete.

**Android technical artifact:** `build/app/outputs/bundle/release/app-release.aab`
(unsigned; not uploadable)  
**Android SHA-256:** `00488695921d0e30647a57c5146c27990ab3d94b3b82433469a28aa7242b5eca`  
**Android signing certificate SHA-256:** `[PENDING OWNER CONFIRMATION]`  
**iOS unsigned Release app:** `build/ios/iphoneos/Runner.app`  
**iOS archive/IPA path:** `[PENDING APPLE SIGNING]`  
**iOS IPA SHA-256:** `[PENDING SIGNED EXPORT]`  
**Apple Team ID:** `[PENDING OWNER CONFIRMATION]`  
**Privacy-policy URL:** `[PENDING PUBLICATION]`  
**Release approver:** `[PENDING]`  
**Approval date:** `[PENDING]`

## Authoritative policy references

- [Google Play target API requirements](https://developer.android.com/google/play/requirements/target-sdk)
- [Android 16 KB page-size guidance](https://developer.android.com/guide/practices/page-sizes)
- [Android TextToSpeech package visibility](https://developer.android.com/reference/android/speech/tts/TextToSpeech)
- [Flutter Android signing guidance](https://docs.flutter.dev/deployment/android)
- [Google Play Families policy](https://support.google.com/googleplay/android-developer/answer/17190352?hl=en)
- [Apple upcoming SDK requirements](https://developer.apple.com/news/upcoming-requirements/)
- [Apple Kids guidance](https://developer.apple.com/kids/)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple required-reason API guidance](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

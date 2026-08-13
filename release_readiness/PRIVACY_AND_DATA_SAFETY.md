# Coloriboo Privacy and Data Safety Assessment

**Assessment date:** 2026-08-13  
**Assessed source version:** `1.0.0+1`  
**Scope:** Current Flutter, Android, iOS, dependency lock, and cached native
build evidence  
**Release status:** Conditional — final signed-binary verification required

This is the technical/privacy handoff for release. It supports, but does not
replace, publisher legal review, the public policy in
`docs/PRIVACY_POLICY.md`, or the store-specific forms.

## Executive finding

Current Coloriboo source is deliberately data-minimizing. It contains no
account, child-profile field, developer backend, analytics, ads, tracking,
attribution, diagnostics uploader, purchase flow, chat, social feature, or
user-content input. Current-session learning state and parent choices stay in
application memory. Local audio uses bundled files; optional speech delegates
fixed app-authored phrases to the device text-to-speech service.

If the final AAB/IPA and all embedded SDKs match this behavior, the defensible
store declarations are:

- **Apple App Privacy:** Data Not Collected; Tracking: No.
- **Google Play Data safety:** no user data collected; no user data shared.

Those are working conclusions, not completed store declarations. Clean
unsigned Release-product inspection confirms the framework privacy manifest is
packaged correctly; the final signed archive, privacy report, and store gates
below must still be completed.

## App identity in scope

| Platform | Identifier | Decision |
|---|---|---|
| Android | `com.example.colorsquest` | Explicitly preserved by owner instruction |
| iOS/iPadOS | `com.example.colorsquest` | Explicitly preserved by owner instruction |
| User-facing name | `Coloriboo` | Current Android, iOS, and Flutter label |

The identifier contains `example`, but this assessment does not recommend or
authorize a rename. Store privacy records and artifacts must use the exact
current identity.

## Data-flow inventory

| Item handled | Source | Purpose | Storage | Off-device transfer by Coloriboo | Retention |
|---|---|---|---|---|---|
| Current activity and round | App-generated random/game state | Run the learning activity | Application memory | No | Until screen/session replacement or app close |
| Colors explored | Child taps and app-generated rounds | Current end-session memory | Application memory | No | Cleared on Home, new session, or app close |
| Activity/success/shade counts | Child interaction | Current end-session summary | Application memory | No | Cleared on Home, new session, or app close |
| Music/SFX/voice/word toggles | Parent or child control | Configure current app session | Application memory | No | Reset when the app process terminates/restarts |
| Master mute | Child/parent control | Temporarily silence output | Application memory | No | Reset when the app process terminates/restarts |
| Fixed prompt text | App source strings | Optional spoken instruction/encouragement | Passed to selected platform TTS service | Not sent to a Coloriboo server; provider behavior depends on device voice | Provider/OS dependent; Coloriboo keeps no history |
| Bundled WAV/PNG assets | App package | Audio and display | App bundle; audio library may copy WAVs to app temp | No | App install plus OS-managed temporary copies |
| Generated audio tone | App color data | Nonverbal color cue | Audio engine memory | No | Current playback/engine lifetime |

There is no persistent saved-progress model. The end screen is a memory of the
current visit, not an account, leaderboard, or longitudinal child record.

## Data types not present in current product code

The audit found no current feature or configured SDK that collects:

- name, email address, phone number, postal address, or other contact info;
- account credentials, user ID, profile, age, birthday, or parent identity;
- precise or approximate location;
- contacts, messages, emails, photos, videos, drawings, or files;
- microphone recordings, camera images, voiceprints, or biometric data;
- health, fitness, financial, payment, or purchase data;
- browsing/search history or user-entered text;
- advertising ID or developer access to a persistent device identifier;
- product interaction analytics, advertising data, diagnostics uploads, crash
  reports, performance telemetry, or attribution data; or
- content shared with other users.

This list must be re-audited if code or dependencies change.

## Platform access and permissions

### Android

- The main manifest declares no `uses-permission` entries.
- It declares narrow package-visibility intents for `PROCESS_TEXT` (Flutter
  engine support) and `TTS_SERVICE` (Android 11+ speech-engine discovery).
  These are not runtime permissions and do not themselves transmit child data.
- Debug and profile manifests request `INTERNET` for Flutter tooling. Those
  variants must not be uploaded or described as the production app.
- The final merged release manifest is pending and can differ because of
  library manifest merging; inspect it before signing the Data safety form.

### iOS / iPadOS

- Source `Info.plist` has no location, contacts, microphone, camera, photos,
  Bluetooth, motion, health, speech recognition, or other protected-resource
  usage string.
- Source has no background modes, ATS exception, or entitlement file.
- Cached debug builds can contain Flutter debugging/local-network metadata;
  confirm it is absent from the Release archive.
- A privacy manifest reports data/required-reason API behavior; it is not a
  runtime permission prompt and does not replace App Store privacy answers.

## Component and SDK assessment

| Component | Locked/current evidence | How Coloriboo uses it | Data/privacy conclusion |
|---|---|---|---|
| Flutter | SDK framework | UI, rendering, app lifecycle | Flutter framework's cached manifest reported no tracking/collection; final framework must still be checked |
| `cupertino_icons` | `1.0.9` | Bundled icon font | No data flow |
| `flutter_tts` | `4.2.5` | Sends fixed app prompts to OS text-to-speech | No child speech/text input; an independently selected voice provider may use network synthesis |
| `flutter_soloud` | `3.5.4` | `loadAsset`, `loadWaveform`, play/stop/fade | No URL load; app Podfile injects the framework's required privacy resource |
| Transitive `http` | `1.6.0` | Not imported or called by Coloriboo source | Presence in lockfile alone is not current collection; final binary/network behavior still requires verification |
| Transitive `path_provider` | `2.1.6` | Used by SoLoud loader internals | Bundled audio may be copied to private OS temp storage; not user data |

### Text-to-speech qualification

The app speaks color names, instructions, and encouragement defined in source.
It neither opens the microphone nor accepts child-authored free-form text. On
Apple platforms, the platform speech synthesizer is an OS service. On Android,
the family can select a speech engine/voice, including one that declares that a
network connection is required. Therefore:

- the publisher does not receive the phrases or synthesized audio;
- the phrases are app content, not child-provided user content;
- Coloriboo should not market every possible voice as offline;
- the public policy should disclose the independent speech-provider boundary;
  and
- final testing should cover no TTS engine, an embedded/offline voice, and a
  network-required voice.

### Local-audio qualification

`AudioService` calls only SoLoud asset/waveform APIs and wraps failures and
timeouts so optional audio cannot block play. The plugin can copy packaged WAV
files to the app's private temporary directory; its current loader behavior
does not make those files user data. There is no recording or audio upload.

## Apple required-reason API packaging

The cached device build used in the audit contained:

- a valid `Flutter.framework/PrivacyInfo.xcprivacy` reporting no tracking or
  collected data and declaring Flutter's required-reason APIs; and
- an embedded `flutter_soloud.framework` with no `PrivacyInfo.xcprivacy`, while
  its executable referenced `fstat` and `mach_absolute_time`.

Apple classifies those calls under required-reason API categories. Apple also
states that each executable or dynamic library's bundle must contain the
declaration for APIs used by that executable/library; one framework cannot rely
on another framework or the app to report its use.

Current source resolves the framework-level omission with
`ios/PrivacyManifests/flutter_soloud/PrivacyInfo.xcprivacy`. The Podfile adds it
to the dynamic framework target, declaring FileTimestamp `C617.1` for private
app-container audio-file metadata and SystemBootTime `35F9.1` for elapsed-time
audio timers. Two consecutive pod installs produced exactly one Resources
entry. This corrects source packaging; it does not imply SoLoud collects data.

The clean unsigned Release product now contains and validates the manifest
inside `flutter_soloud.framework`. Final proof remains generating the signed
archive's Xcode privacy report and resolving all validation messages.

`flutter pub outdated` currently reports SoLoud 4.1.7. That major version has
native fixes but is breaking and still does not publish this privacy resource,
so version chasing would not replace the audited packaging fix.

## Child-directed policy posture

Coloriboo's design and copy are clearly directed to young children. The current
source supports a low-data posture appropriate for that audience:

- no third-party advertising;
- no third-party analytics;
- no personal or device information sent to a publisher backend;
- no chat or user-generated content;
- no purchase opportunity;
- no account requirement; and
- encouraging feedback without public scores or competition.

The owner should select Google **Ages 5 & Under** and Apple Kids **5 and under**
only if that is the intended distribution audience and after completing all
applicable policy/legal review.

Apple Kids submissions must reserve external links and other adult activities
for a parental gate requiring an adult-level task. The current settings long
press is an accidental-tap safeguard, not proven age assurance. A future
in-app privacy/support link must be both accessible to adults and gated as
required for the selected category.

## Working store declarations

### Google Play

Pending final AAB and SDK review:

- data collected: **No**;
- data shared: **No**;
- ads: **No**;
- account creation/deletion: **Not applicable — no account**;
- privacy-policy URL: `[PENDING PUBLIC HTTPS URL]`;
- target audience: `[PENDING PUBLISHER APPROVAL; WORKING 5 & UNDER]`.

Google requires every published app, including a no-data app, to complete Data
safety and provide a privacy policy. The form covers embedded SDK behavior, not
only first-party Dart calls.

### Apple

Pending final archive and privacy report:

- App Privacy data types: **Data Not Collected**;
- tracking: **No**;
- privacy-policy URL: `[PENDING PUBLIC HTTPS URL]`;
- privacy choices URL: not needed unless a real choices page is published;
- Kids age band: `[PENDING PUBLISHER APPROVAL; WORKING 5 AND UNDER]`.

Apple defines on-device-only processing that is never sent to a server as not
“collected” for its label. The publisher must still include integrated partner
behavior and answer at the app level.

## Public-policy publication gate

Before submission:

- [ ] Replace every placeholder in `docs/PRIVACY_POLICY.md`.
- [ ] Confirm publisher legal name, address requirements, and privacy/support
      contacts.
- [ ] Obtain legal/publisher approval for every jurisdiction distributed.
- [ ] Publish a stable, public, mobile-readable HTTPS HTML page.
- [ ] Put the same URL in both store consoles.
- [ ] Add an easily accessible link inside the grown-up area, using a genuine
      parental gate if required by Kids-category placement.
- [ ] Confirm policy text and store labels match the exact final binary.

## Final privacy verification gate

- [ ] Freeze `pubspec.lock`, CocoaPods/Swift packages, and Gradle resolution.
- [ ] Scan final source for network clients, URL loading, analytics, ads,
      identifiers, persistence, and protected-resource APIs.
- [ ] Build a signed Release AAB and record path/SHA-256:
      `[PENDING FINAL ANDROID ARTIFACT]`.
- [ ] Inspect the merged release manifest and Play SDK inventory.
- [ ] Capture Android network traffic during representative offline and online
      sessions, distinguishing OS TTS provider traffic from the app process.
- [ ] Build a signed Release archive/IPA and record path/SHA-256:
      `[PENDING FINAL IOS ARTIFACT]`.
- [ ] Inspect archive entitlements, usage strings, linked frameworks, privacy
      manifests, and signatures.
- [ ] Generate and retain Xcode's privacy report:
      `[PENDING FINAL REPORT]`.
- [ ] Confirm no unexpected network request during start, all five activities,
      Finish, Play Again, Home, background/resume, and audio shutdown.
- [ ] Reconcile results with Apple/Google forms immediately before submission.

## Change-control triggers

Stop release and repeat this assessment if any change introduces or alters:

- accounts, authentication, profiles, age gates that store birthdate, or cloud
  saves;
- persisted learning progress, parent reports, backups, or cross-device sync;
- crash reporting, analytics, remote configuration, experiments, attribution,
  or support SDKs;
- ads, purchases, subscriptions, payments, promotions, or external links;
- network-fetched content, remote audio, web views, or push notifications;
- microphone, speech recognition, camera, photos, files, contacts, location,
  Bluetooth, health, or motion;
- user-entered text, drawings, uploads, chat, or social sharing;
- device identifiers, integrity/fraud signals, or fingerprinting-related APIs;
- a runtime dependency or native SDK version; or
- the selected target audience, countries, business model, or store identity.

## Privacy sign-off

**Final lockfile commit/tree:** `[PENDING]`  
**Android artifact/hash:** `[PENDING]`  
**iOS artifact/hash:** `[PENDING]`  
**Xcode privacy report:** `[PENDING]`  
**Public privacy URL:** `[PENDING]`  
**Google Data safety reviewed by:** `[PENDING]`  
**Apple App Privacy reviewed by:** `[PENDING]`  
**Publisher/legal approver:** `[PENDING]`  
**Approval date:** `[PENDING]`

## Official references

- [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Google Play Target audience](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en-GB)
- [Google Play Families policy](https://support.google.com/googleplay/android-developer/answer/17190352?hl=en)
- [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Apple App Privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple App Privacy management](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Apple Kids guidance](https://developer.apple.com/kids/)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple required-reason API guidance](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

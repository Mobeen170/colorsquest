# Coloriboo Google Play Release Checklist

**Snapshot:** 2026-08-13  
**Status:** Open — do not upload until every P0 item is checked  
**Package identity:** `com.example.colorsquest` — intentionally preserved

Use this checklist for the exact signed candidate. A successful debug run is
not release evidence.

## 1. Identity and Play Console record

- [ ] Confirm the intended Play Console app record uses
      `com.example.colorsquest` exactly.
- [ ] Do **not** rename the application ID, namespace, or Kotlin package merely
      because the identifier contains `example`; preservation is an explicit
      owner instruction.
- [ ] Set the Play listing app name to **Coloriboo**.
- [ ] Confirm the publisher/developer display name:
      `[PENDING OWNER VALUE]`.
- [ ] Confirm whether `1.0.0` / version code `1` is unused and correct for this
      record. If not, raise the build number without changing the package ID.
- [ ] Choose the primary category **Education** unless the publisher makes a
      documented alternative decision.
- [ ] Complete developer contact email, phone, website, and physical-address
      fields required for the publisher account.

## 2. Release signing and Play App Signing — P0

Current Gradle source loads an optional, gitignored `android/key.properties`
and no longer assigns the public Flutter debug key to release. The repository
does not contain a key file or keystore, so the release variant currently has
no signing configuration and any generated AAB is expected to be unsigned. It
must not be treated as an upload candidate.

- [ ] Decide whether this is an existing Play app or a new app.
- [ ] Existing app: retrieve the exact existing upload key; do not generate a
      replacement unless following Google's approved reset process.
- [ ] New app: create and securely back up the approved upload key, then enroll
      in Play App Signing.
- [ ] Create local `android/key.properties` with only:

  ```properties
  storePassword=[SECRET]
  keyPassword=[SECRET]
  keyAlias=[UPLOAD KEY ALIAS]
  storeFile=[ABSOLUTE OR APP-MODULE-RELATIVE KEYSTORE PATH]
  ```

  A relative `storeFile` value is resolved from the `android/app` module
  directory.

- [ ] Confirm `android/key.properties`, `*.jks`, and `*.keystore` stay ignored
      and are not present in `git status` or staged content.
- [ ] Build the bundle with the correct secret file available.
- [ ] Inspect the candidate certificate and compare its SHA-256 with the owner
      or Play Console value.
- [ ] Save the upload certificate separately from the keystore backup.

**Expected upload certificate SHA-256:** `[PENDING OWNER VALUE]`  
**Actual candidate certificate SHA-256:** `[PENDING FINAL BUILD]`  
**Match:** `[PENDING]`

## 3. Android configuration

Current audited local values:

| Setting | Value | Status |
|---|---:|---|
| Application ID / namespace | `com.example.colorsquest` | Frozen by owner instruction |
| App display label | `Coloriboo` | Present |
| Version name / code | `1.0.0` / `1` | Owner/store confirmation pending |
| Compile SDK | 36 | Meets current toolchain needs |
| Target SDK | 36 | Meets Google Play's 2026 Android 16 requirement |
| Minimum SDK | 24 | Current Flutter-resolved value |
| NDK | `28.2.13676358` | Suitable prerequisite for 16 KB builds |
| Java/Kotlin bytecode target | 17 | Present |
| AGP / Gradle / Kotlin | `9.0.1` / `9.1.0` / `2.3.20` | Present; final build still required |

- [ ] Confirm these are the values resolved by the final CI/build machine.
- [ ] Confirm the Play Console target-API check passes after upload.
- [ ] Review the generated `versionName` and `versionCode` inside the AAB.
- [x] Branded source uses approved Boo artwork on `#EAF9FF` for the launcher,
      legacy launch background, and Android 12+ day/night splash.
- [ ] Confirm the adaptive mask, label, launch background, and app name on at
      least two installed Android launchers.

## 4. Manifest, permissions, and package visibility

The source main manifest currently requests no runtime permissions. It declares
only package visibility for Flutter `PROCESS_TEXT` handling and Android 11+
text-to-speech service discovery. Debug/profile manifests add `INTERNET` for
Flutter tooling.

- [x] Inspect the **merged release manifest** produced by the technical AAB.
- [x] Confirm no `INTERNET` permission is inherited into release unless a
      separately approved feature genuinely requires it.
- [ ] Confirm there is no advertising ID, location, camera, microphone,
      contacts, storage, notification, Bluetooth, or background permission.
- [ ] Confirm no unexpected exported activity, service, receiver, or provider.
- [ ] Confirm `android.intent.action.TTS_SERVICE` remains under `<queries>`.
- [ ] Confirm `PROCESS_TEXT` is the standard Flutter query, not a broad package
      inventory request.

**Merged release manifest evidence:**
`build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`

## 5. Native libraries and 16 KB page size — P0/P1

Coloriboo embeds native Flutter and SoLoud libraries. AGP 9 and NDK r28 are the
right prerequisites but are not proof that every packaged `.so` is aligned.
Google Play has required 16 KB page-size support for applicable Android 15+
submissions since 2025-11-01.

- [x] Build an unsigned technical release AAB; rebuild it with owner signing
      before upload.
- [x] Verify the bundle configuration uses `PAGE_ALIGNMENT_16K`.
- [x] Extract or inspect every native `.so` with Android's official alignment
      tooling/script.
- [ ] Confirm Play Console reports no 16 KB compatibility error.
- [ ] Install and run the release candidate on a 16 KB Android 15/16 emulator
      or physical device.
- [ ] Exercise app start, all five activities, audio initialization/play/stop,
      background/resume, Finish, Play Again, and Home.

**16 KB report/tool output:** BundleConfig `PAGE_ALIGNMENT_16K`; 27/27 ELF
libraries use LOAD alignment `2**14` or `2**16`  
**16 KB test device:** `[PENDING DEVICE / OS / PAGE SIZE]`

## 6. Build and artifact evidence

Suggested final commands, run from the repository root after secrets are
configured:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build appbundle --release
```

- [ ] All commands exit successfully with the final lockfile and tree.
- [ ] Do not weaken or delete tests to obtain a green result.
- [ ] Copy the exact AAB to controlled release storage.
- [ ] Record its hash before upload.
- [ ] Upload first to an internal/closed test track.
- [ ] Review Play's pre-launch report, SDK report, device catalog exclusions,
      accessibility findings, stability findings, and policy warnings.

**Analyze result:** `No issues found!`  
**Test result:** 163 / 163 passed  
**AAB path:** `build/app/outputs/bundle/release/app-release.aab` (unsigned
technical artifact)  
**AAB size:** 93,928,754 bytes  
**AAB SHA-256:** `00488695921d0e30647a57c5146c27990ab3d94b3b82433469a28aa7242b5eca`  
**Play internal-test release:** `[PENDING URL / RELEASE ID]`

## 7. Privacy policy and Data safety — P0

- [ ] Replace every placeholder in `docs/PRIVACY_POLICY.md`.
- [ ] Obtain publisher/legal approval.
- [ ] Host the policy as active, public, non-geoblocked HTML over HTTPS.
- [ ] Set Play Console privacy-policy URL:
      `[PENDING PUBLIC HTTPS URL]`.
- [ ] Add an accessible in-app policy link in the grown-up area before release.
- [ ] Recheck all dependencies and the final AAB for off-device data transfer.
- [ ] Complete Data safety. Current source-based working answer is **no data
      collected and no data shared**, conditional on final artifact review.
- [ ] Declare **no ads**; confirm Play's SDK inventory agrees.
- [ ] Confirm there is no account and therefore no account-deletion requirement.
- [ ] Reconcile every Console answer with
      `docs/STORE_DATA_SAFETY_NOTES.md` and
      `release_readiness/PRIVACY_AND_DATA_SAFETY.md`.

Do not describe every TTS voice as offline. Coloriboo sends only fixed
app-authored prompts to the selected device speech engine, but an independently
selected Android provider can use a network-required voice.

## 8. Target audience, Families, ads, and content — P0

Current UI, copy, controls, and learning scope are explicitly child-directed.
Google says an app designed for babies, toddlers, or preschool children should
select only **Ages 5 & Under**. The publisher must confirm the intended audience
and applicable law before saving the form.

- [ ] Complete **Target audience and content** accurately.
- [ ] Working selection: **Ages 5 & Under** — `[PENDING PUBLISHER APPROVAL]`.
- [ ] Do not add adult age groups only to broaden distribution.
- [ ] Confirm **contains ads: No**.
- [ ] Confirm **in-app purchases: No**.
- [ ] Confirm **app access: all functionality available without login**.
- [ ] Complete Families-policy declarations.
- [ ] Complete the IARC questionnaire from actual content; do not copy an
      assumed rating into the form.
- [ ] Declare no chat, user-generated content, social features, web browsing,
      gambling, simulated gambling, violence, sexual content, profanity,
      controlled substances, or location sharing, if the final candidate still
      matches current code.
- [ ] Confirm all store artwork and text are age-appropriate and accurately show
      the app.

## 9. Store listing and assets

Draft copy is in `release_readiness/STORE_LISTING_COPY.md`.

- [ ] App name: **Coloriboo**.
- [ ] Short description: choose and approve the Google draft.
- [ ] Full description: approve, localize if required, and verify every claim.
- [ ] Support URL: `[PENDING PUBLIC HTTPS URL]`.
- [ ] Privacy URL: `[PENDING PUBLIC HTTPS URL]`.
- [ ] Developer contact email: `[PENDING]`.
- [ ] Upload a 512×512 high-resolution icon exported from the approved icon.
- [ ] Create a 1024×500 feature graphic from approved Coloriboo artwork.
- [ ] Capture phone screenshots from the final candidate.
- [ ] Capture tablet screenshots because the app supports large layouts.
- [ ] Do not use staging artwork or imply features, rewards, saved progress,
      multiplayer, or personalization that are not present.
- [ ] Check spelling by locale: source UI intentionally contains both “color”
      brand copy and British-style activity names such as “Colour Mixing Lab.”

## 10. Manual release-candidate test

- [ ] Clean install on minimum supported Android/API 24 device or emulator.
- [ ] Clean install on a current Android 16/API 36 device.
- [ ] Small phone portrait and landscape.
- [ ] Normal phone portrait and landscape.
- [ ] Large phone/foldable where available.
- [ ] 7–8 inch tablet and 10+ inch tablet.
- [ ] Start → branded loader → activity world has no exception or dead end.
- [ ] Pop the Colour works for correct and repeated incorrect taps.
- [ ] Odd One Out works for correct and repeated incorrect taps.
- [ ] Boo's Magic shows and accepts all teaching colors.
- [ ] Colour Mixing Lab drag/merge/reveal completes.
- [ ] Light to Dark selection/swap/completion completes.
- [ ] Endless loop advances and does not immediately repeat the same activity.
- [ ] Wrong answers stay encouraging, name the selected color, hint, and remain
      playable.
- [ ] Boo state artwork does not stretch, crop, flash, or show a stale state.
- [ ] Missing optional audio, mute, TTS failure, and airplane mode cannot crash
      or block play.
- [ ] Reduced-motion/Remove animations removes nonessential transitions while
      retaining understandable state changes.
- [ ] Background/resume and audio focus behave acceptably.
- [ ] Finish for now, session summary, Play Again, Home, and back navigation.
- [ ] TalkBack labels and touch targets on the start, activity, parent, and end
      screens.

## 11. Rollout and post-upload

- [ ] Add concise release notes for `1.0.0` if the Console requests them.
- [ ] Use internal testing first, then closed testing as required by the account.
- [ ] Add testers and verify install/update behavior through Play, not adb only.
- [ ] Review automated testing without adding a production analytics SDK.
- [ ] Choose countries/regions, pricing (free/paid), and distribution settings.
- [ ] Save all policy-form exports/screenshots with the release record.
- [ ] Obtain final publisher sign-off before production rollout.

**Play submission owner:** `[PENDING]`  
**Final review date:** `[PENDING]`  
**Production rollout decision:** `[PENDING]`

## Official references

- [Target API requirement](https://developer.android.com/google/play/requirements/target-sdk)
- [16 KB page-size support](https://developer.android.com/guide/practices/page-sizes)
- [TextToSpeech package visibility](https://developer.android.com/reference/android/speech/tts/TextToSpeech)
- [App signing](https://developer.android.com/studio/publish/app-signing)
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Target audience and content](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en-GB)
- [Families policies](https://support.google.com/googleplay/android-developer/answer/17190352?hl=en)
- [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)

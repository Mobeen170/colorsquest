# Coloriboo App Store Release Checklist

**Snapshot:** 2026-08-13  
**Status:** Open — signing, final privacy proof, and archive evidence pending  
**Bundle identity:** `com.example.colorsquest` — intentionally preserved

Use this checklist for the exact Release archive submitted to App Store
Connect. Simulator and unsigned device builds are not submission evidence.

## 1. Identity and App Store Connect record

- [ ] Register or select the explicit App ID `com.example.colorsquest`.
- [ ] Create/select the App Store Connect app record for that exact bundle ID.
- [ ] Do **not** rename the bundle ID because it contains `example`; preserving
      it is an explicit owner instruction.
- [ ] App name: **Coloriboo**.
- [ ] Subtitle draft: **Pop, play & learn colors**.
- [ ] SKU: `[PENDING OWNER VALUE]`.
- [ ] Primary language: `[PENDING OWNER VALUE; SUGGESTED en-US]`.
- [ ] Confirm the publisher/seller legal name and agreements are active.
- [ ] Confirm whether `1.0.0` / build `1` is unused for this app record. If not,
      increment the build without changing the bundle ID.

Current test target bundle ID is `com.example.colorsquest.RunnerTests`; preserve
it unless the owner authorizes a separate identity migration.

## 2. Apple Developer signing — P0

Runner has no selected `DEVELOPMENT_TEAM`; signing style must be confirmed when
the owner selects a team. The audit machine reported zero valid code-signing
identities.

- [ ] Confirm active Apple Developer Program membership.
- [ ] Select the correct team for the Runner target.
- [ ] Install or create an Apple Distribution certificate.
- [ ] Create/select the App Store provisioning profile for
      `com.example.colorsquest`, or allow Xcode automatic signing to manage it.
- [ ] Confirm the exact entitlements required. Current source has no entitlement
      file and no feature needs one.
- [ ] Confirm the archive's Team ID, application identifier, profile UUID,
      signing certificate, and entitlements.
- [ ] Do not add capabilities just to make signing succeed.

**Apple Team ID:** `[PENDING OWNER VALUE]`  
**Distribution certificate SHA-256:** `[PENDING]`  
**Profile name / UUID:** `[PENDING]`

## 3. Platform and toolchain configuration

| Setting | Current value | Release action |
|---|---|---|
| Bundle display/name | `Coloriboo` | Confirm on installed build |
| Bundle ID | `com.example.colorsquest` | Frozen by owner instruction |
| Version / build | `1.0.0` / `1` | Confirm unused in App Store Connect |
| Deployment target | iOS 13.0 | Set in Runner and Podfile |
| Device families | iPhone and iPad | Capture/test both |
| iPhone orientations | Portrait, landscape left/right | Test every declared orientation |
| iPad orientations | Portrait, upside down, landscape left/right | Test every declared orientation |
| Swift language mode | 5.0 | Present |
| Audit Xcode | 26.3 (17C529) | Meets current Xcode 26+ upload minimum |
| Audit iOS SDK | 26.2 | Meets current iOS 26+ SDK minimum |
| Native launch | Canonical Boo, aspect-fit, pale-blue background | Confirm on installed Release build |

- [ ] Run the final build with Xcode 26 or later and an iOS 26 SDK or later.
- [ ] Confirm CocoaPods resolves deployment target 13.0 without overrides or
      warnings.
- [ ] Confirm the final archive contains only intended architectures.
- [ ] Confirm no debug Flutter service, Bonjour declaration, local-network
      usage text, or debug entitlement appears in the Release archive.
- [ ] Confirm the App Store 1024 icon is opaque and that all required icon slots
      validate.
- [ ] Visually inspect the icon on light/dark home screens and common masks.

Apple's current SDK rule has applied since 2026-04-28. See [Upcoming
Requirements](https://developer.apple.com/news/upcoming-requirements/).

## 4. Native privacy manifests — final proof required

The earlier cached build exposed a real packaging gap: its dynamic
`flutter_soloud.framework` called `fstat` and `mach_absolute_time` but had no
privacy manifest. Current source keeps the tested SoLoud 3.5.4 runtime and
injects `ios/PrivacyManifests/flutter_soloud/PrivacyInfo.xcprivacy` directly
into that Pod target's Resources phase. It truthfully declares `C617.1` for
metadata of app-container audio files and `35F9.1` for elapsed-time audio
timers. Repeated `pod install` is idempotent.

- [x] Add the required-reason manifest to the correct dynamic framework target.
- [ ] Rebuild from a clean dependency state.
- [x] Confirm `Runner.app/Frameworks/flutter_soloud.framework/PrivacyInfo.xcprivacy`
      exists and validates in the final Release product.
- [x] Inspect every `PrivacyInfo.xcprivacy` in the unsigned Release product for valid keys and
      truthful values.
- [ ] Generate the Xcode Organizer privacy report.
- [ ] Confirm App Store Connect produces no invalid/missing privacy-manifest or
      required-reason API warning.

**Chosen SoLoud resolution:** app-owned CocoaPods resource injection  
**Resolved package version:** `flutter_soloud 3.5.4`  
**Privacy report path:** `[PENDING FINAL ARCHIVE]`

Relevant Apple guidance:

- [Describing required-reason API use](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Adding a privacy manifest](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk)

## 5. App Privacy and public privacy policy — P0

- [ ] Replace placeholders in `docs/PRIVACY_POLICY.md`.
- [ ] Obtain publisher/legal approval.
- [ ] Host the policy as active public HTML over HTTPS.
- [ ] App Store Connect Privacy Policy URL:
      `[PENDING PUBLIC HTTPS URL]`.
- [ ] Add an easily accessible policy link inside the app's grown-up area.
- [ ] If the app is submitted to the Kids category, place external link-outs
      behind a genuine adult-level parental gate.
- [ ] Generate the final archive privacy report and include all embedded
      third-party SDK behavior in App Privacy answers.
- [ ] Working source-based App Privacy answer: **Data Not Collected** and
      **Tracking: No**, pending final archive verification.
- [ ] Leave Privacy Choices URL blank unless the publisher hosts a real choices
      page. Coloriboo has no account or developer-held user record.

The current long press used to open grown-up settings reduces accidental child
taps but is not by itself proof of Apple's adult-level parental-gate task.

Do not state that every text-to-speech voice is offline. The app supplies only
fixed learning phrases and records no microphone input, but a user-selected
speech provider may independently use network synthesis.

## 6. Kids category, age rating, and safety — P0

The app's copy and interaction design target young children. If the publisher
uses the Kids category:

- [ ] Working age-band choice: **5 and under** —
      `[PENDING PUBLISHER APPROVAL]`.
- [ ] Answer Apple's updated age-rating questionnaire from the final app.
- [ ] Declare messaging/chat: no.
- [ ] Declare advertising: no.
- [ ] Declare in-app purchases: no.
- [ ] Declare user-generated content: no.
- [ ] Declare unrestricted web access: no.
- [ ] Declare location sharing: no.
- [ ] Declare parental controls only if the implemented controls satisfy Apple's
      definition; do not equate the settings long press with age assurance.
- [ ] Keep all link-outs, purchases, and adult distractions out of the child
      area. Current app has none.
- [ ] Confirm third-party libraries do not transmit personally identifiable or
      device information and do not provide analytics or advertising.
- [ ] Confirm screenshots, preview video, description, and keywords are
      age-appropriate and show only real app behavior.

Apple's current age bands are 5 and under, 6–8, and 9–11 for Kids-category
placement. See [Apple's Kids guidance](https://developer.apple.com/kids/) and
[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

## 7. Encryption and export compliance

Current Coloriboo code does not implement custom encryption or a developer
network service. Store export-compliance answers remain a publisher/legal
representation and must be based on the final binary and distribution regions.

- [ ] Review all embedded frameworks for encryption functionality.
- [ ] Determine whether the app uses only exempt encryption supplied by Apple/
      standard platform components.
- [ ] Answer App Store Connect export-compliance questions accurately.
- [ ] Add `ITSAppUsesNonExemptEncryption` only after that determination; do not
      use a guessed value to skip a form.
- [ ] Retain any required classification or legal documentation.

**Export determination:** `[PENDING PUBLISHER/LEGAL CONFIRMATION]`

## 8. Build, archive, and artifact evidence

Run source validation before opening the workspace for the final archive:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build ios --release
open ios/Runner.xcworkspace
```

Then use Xcode's **Product → Archive** with the approved team and Release
configuration.

- [ ] Source checks pass without weakening tests.
- [ ] `pod install`/Swift package resolution is clean and reproducible.
- [ ] Archive validation passes.
- [ ] Archive is signed for App Store distribution, not development/ad hoc.
- [ ] Inspect archive bundle IDs, version/build, entitlements, signatures,
      embedded frameworks, privacy manifests, symbols, and dSYMs.
- [ ] Distribute to App Store Connect/TestFlight.
- [ ] Wait for processing and resolve every compliance message.
- [ ] Install the processed TestFlight build on physical devices.

**Analyze result:** `No issues found!`  
**Test result:** 163 / 163 passed  
**Unsigned Release app:** `build/ios/iphoneos/Runner.app` (about 60 MiB;
build passed; not a submission artifact)  
**Simulator validation:** fresh app built, installed, launched, and rendered on
iPhone 16e  
**XCArchive path:** `[PENDING FINAL BUILD]`  
**IPA path:** `[PENDING FINAL EXPORT]`  
**IPA SHA-256:** `[PENDING FINAL EXPORT]`  
**App Store Connect build:** `[PENDING VERSION / BUILD]`

## 9. App Store listing

Draft metadata and captions are in
`release_readiness/STORE_LISTING_COPY.md`.

- [ ] Name: **Coloriboo**.
- [ ] Subtitle: approve the draft and verify Apple's current character count.
- [ ] Promotional text: approve and verify every claim.
- [ ] Description: approve and localize as needed.
- [ ] Keywords: approve; do not duplicate the app name unnecessarily.
- [ ] Primary category: suggested **Education**.
- [ ] Secondary category/Kids placement: publisher decision pending.
- [ ] Support URL: `[PENDING PUBLIC HTTPS URL]`.
- [ ] Marketing URL: `[OPTIONAL / PENDING]`.
- [ ] Privacy Policy URL: `[PENDING PUBLIC HTTPS URL]`.
- [ ] Copyright: `[PENDING YEAR + RIGHTS HOLDER]`.
- [ ] Content rights: confirm the publisher owns/licenses all Boo artwork,
      audio, icon, copy, and code.
- [ ] Upload current iPhone screenshots.
- [ ] Upload iPad screenshots because the binary supports iPad.
- [ ] If uploading an app preview video, capture only the final build and avoid
      audio/music for which video-distribution rights are unconfirmed.

## 10. App Review information

- [ ] Review contact name: `[PENDING]`.
- [ ] Review phone: `[PENDING]`.
- [ ] Review email: `[PENDING]`.
- [ ] Sign-in required: **No**.
- [ ] Demo account: **Not applicable**.
- [ ] Provide concise review notes explaining the no-login flow, grown-up
      settings entry, optional Finish path, and audio/TTS behavior.
- [ ] If the policy link uses a parental gate, give reviewers exact steps.

Suggested review note:

> Coloriboo is a no-account color-learning app for young children. Tap PLAY to
> enter an endless sequence of five short activities with Boo. The top-left
> home control can return to the start screen, and “Finish for now” opens an
> on-device session summary. Sound and written-word choices are in the grown-up
> settings. The app contains no ads, purchases, analytics, or user-generated
> content. Boo's optional voice speaks fixed app-authored prompts using the
> device text-to-speech service; the app never records the microphone.

Update control directions against the final UI before submission.

## 11. Physical-device and TestFlight acceptance

- [ ] Minimum supported iOS 13 device if one is available; otherwise document
      the oldest physical/simulator coverage and residual risk.
- [ ] Current iPhone, small iPhone, and large iPhone.
- [ ] Current iPad compact and regular size classes.
- [ ] Portrait and every declared landscape orientation.
- [ ] Dynamic Type and VoiceOver labels/touch order.
- [ ] Reduce Motion enabled.
- [ ] Silent mode, mute switches, headphones, interruptions, background/resume,
      and route changes.
- [ ] Device speech disabled/unavailable and an offline speech voice.
- [ ] Airplane mode from clean launch through all activities.
- [ ] All five activities, repeated misses, hints, correct flow, endless loop,
      Finish, session summary, Play Again, and Home.
- [ ] Boo artwork state changes without crop, stretch, stale frame, or flash.
- [ ] Missing optional audio cannot crash or trap loading.
- [ ] No runtime exception in Xcode device logs or TestFlight diagnostics.

## 12. Submission and phased release

- [ ] Complete pricing/availability and territories.
- [ ] Complete App Privacy, age rating, Kids category, export compliance, and
      content-rights forms.
- [ ] Select the final processed build.
- [ ] Attach screenshots and final metadata.
- [ ] Submit for review only after P0 blockers are closed.
- [ ] Choose manual, automatic, or phased release intentionally.
- [ ] Save a release packet containing archive hash, privacy report, signing
      details, form answers, screenshots, and reviewer notes.

**App Store submission owner:** `[PENDING]`  
**Final review date:** `[PENDING]`  
**Release decision:** `[PENDING]`

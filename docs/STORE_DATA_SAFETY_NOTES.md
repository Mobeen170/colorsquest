# Store Data Safety Notes

**Internal release document — not public policy text**  
**Code snapshot reviewed:** 2026-08-13  
**App:** Coloriboo  
**Version in `pubspec.yaml`:** `1.0.0+1`

These notes translate the current source tree into likely App Store Connect and
Google Play Console answers. Store forms are legal representations by the
publisher. Reconfirm every answer against the final signed AAB and archived IPA,
including all embedded SDKs, before submitting.

## Current source-based conclusion

The current Dart and platform source implements an offline-first children's
learning app with no account, ads, analytics, tracking, developer backend, or
personal-data input. Gameplay and settings are in memory. Bundled audio is
loaded locally, and fixed app-authored phrases can be sent to the operating
system's text-to-speech service.

Subject to final binary and speech-provider verification, the appropriate
store position is:

- **Google Play:** no user data collected and no user data shared.
- **Apple App Privacy:** Data Not Collected; no tracking.

Do not submit those answers until the release-artifact checks in this document
are complete.

## Evidence in the repository

| Behavior | Current evidence | Store/privacy effect |
|---|---|---|
| Accounts and identity | No authentication dependency or account UI in `lib/` | No account identifiers or account deletion flow |
| Gameplay state | `lib/session/session_summary.dart` and `lib/dreamscape.dart` hold session values in memory | On-device processing; not collection under the current implementation |
| Parent settings | `lib/settings/settings.dart` uses a `ChangeNotifier` only | Preferences are never persisted and reset when the app process restarts; no persistent profile |
| Network | No HTTP, socket, URL-loading, API, or backend call in `lib/` | No app-authored off-device transfer |
| Advertising and analytics | No ad, analytics, attribution, Firebase, or crash-reporting dependency | No ad ID, tracking, analytics, or third-party ad sharing |
| Local audio | `lib/audio/audio_service.dart` calls SoLoud `loadAsset` and `loadWaveform`, never `loadUrl` | Bundled media only; temporary asset copies are not user data |
| Speech | `AudioService.speak` sends fixed prompts to `flutter_tts` | Device speech service; no microphone or child input |
| Sensitive device access | Main Android manifest has no `uses-permission`; iOS `Info.plist` has no protected-resource usage strings | No location, contacts, camera, microphone, photo, or storage access requested by source |
| Child-directed design | The UI and learning content target young children | Families/Kids declarations and child-directed policies apply |

Development-only Android manifests request `INTERNET` for Flutter tooling. They
must never be used as store artifacts. The main manifest now declares package
visibility queries for `PROCESS_TEXT` and `TTS_SERVICE`; queries are not runtime
permissions and do not themselves collect data.

## Google Play Data safety working answers

Use the following only after inspecting the signed release bundle in Play
Console and reconciling its SDK report.

| Play Console question | Working answer | Qualification |
|---|---|---|
| Does the app collect or share any required user data types? | **No** | Conditional on final SDK/artifact verification |
| Is user data encrypted in transit? | **Not applicable to app data** | The current app does not transmit user data; answer according to the form wording shown by Play Console |
| Can users request deletion? | **No account/data deletion mechanism is needed** | The app has no account or developer-held user record |
| Is data shared with third parties? | **No** | The app does not send user data to ads, analytics, or a backend |
| Is data processed ephemerally? | **No user-data category to declare** | In-memory gameplay is on-device and is not transmitted |
| Does the app contain ads? | **No** | No ad SDK or ad UI exists |
| Target audience | **Ages 5 & Under — publisher confirmation required** | The present design is explicitly for young/preschool children; select only the audience actually intended |

Even an app that collects no user data must complete the Data safety form and
provide a public privacy-policy URL. Google requires declarations to include
the behavior of third-party SDKs. See [Google Play Data safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en).

## Apple App Privacy working answers

After the final archive privacy report and SDK review pass:

| App Store Connect item | Working answer | Qualification |
|---|---|---|
| Data collection | **Data Not Collected** | On-device-only processing is not Apple “collection”; include all partner SDK behavior in the final review |
| Tracking | **No** | No tracking, fingerprinting, ad SDK, or cross-company linking is configured |
| Privacy policy URL | `[PUBLIC HTTPS PRIVACY POLICY URL]` | Required; this repository Markdown file is not sufficient |
| User privacy choices URL | Leave blank unless a real choices page is published | There is no account or developer-held data to manage |
| Kids age band | **5 and under — publisher confirmation required** | Choose 5 and under, 6–8, or 9–11 based on the actual intended audience |

Apple requires the publisher to include the practices of integrated third-party
code. See [Apple App Privacy details](https://developer.apple.com/app-store/app-privacy-details/).

## Text-to-speech boundary

`flutter_tts` delegates fixed Coloriboo phrases to the speech engine selected
on the device. The app does not select or enforce an embedded/offline-only
voice, and Android speech providers can advertise network-required voices.
Therefore:

- do not claim that every possible voice works offline;
- do not classify the fixed phrases as child-provided content;
- verify default speech behavior on representative Android and Apple devices;
- ensure the public policy explains that an independently selected speech
  provider may process a phrase under its own terms; and
- if a future release accepts free-form text or microphone input, stop and
  redo all privacy declarations.

## Dependency and native-binary review

Current direct runtime packages resolved in `pubspec.lock`:

| Package | Resolved version | Current use | Privacy note |
|---|---:|---|---|
| `cupertino_icons` | `1.0.9` | Local icon font | No data flow |
| `flutter_tts` | `4.2.5` | Platform text-to-speech | Fixed app text goes to the selected OS/provider engine |
| `flutter_soloud` | `3.5.4` | Local effects, music, generated tones | App uses local assets only; transitive `http` is present but unused by Coloriboo code |

The earlier cached iPhone build revealed that `flutter_soloud.framework`
referenced `fstat` and `mach_absolute_time` without its own privacy manifest.
Current source fixes that packaging gap without modifying the dependency:
`ios/PrivacyManifests/flutter_soloud/PrivacyInfo.xcprivacy` declares
FileTimestamp reason `C617.1` for app-container audio-file metadata and
SystemBootTime reason `35F9.1` for elapsed-time audio timers. The Podfile adds
that resource directly to the `flutter_soloud` target, and two consecutive pod
installs produced one idempotent Resources entry. A final clean Release build
now proves the file lands inside the embedded framework and validates as a
property list. The final signed archive must still produce an acceptable Xcode
privacy report. See [Apple's required-reason API guidance](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).

`flutter pub outdated` currently reports SoLoud 4.1.7. Version 4 is a breaking
migration and the published package still does not supply this privacy resource,
so it was deliberately not adopted during final packaging.

## Final artifact checks before answering either store

- [ ] Build a **signed release AAB**, not debug or profile.
- [ ] Save its exact path and SHA-256: `[PENDING FINAL ANDROID ARTIFACT]`.
- [ ] Inspect the merged release manifest and confirm no unexpected permission,
      provider, service, receiver, query, or network security configuration.
- [ ] Review Play Console's SDK inventory after upload.
- [ ] Archive with **Release** configuration in Xcode 26 or later.
- [ ] Save the archive/IPA path and SHA-256: `[PENDING FINAL IOS ARTIFACT]`.
- [ ] Generate Xcode Organizer's privacy report and inspect every framework.
- [ ] Confirm `flutter_soloud.framework` includes a valid privacy manifest for
      every required-reason API it actually uses.
- [ ] Confirm the archive has no unexpected entitlements, usage descriptions,
      tracking domains, or embedded SDKs.
- [ ] Test Boo's voice with an offline voice and a network-required voice, or
      disable unsupported network voices if the product requires strict offline
      speech.
- [ ] Re-scan Dart and native code for network, analytics, ads, identifiers,
      persistence, and sensitive permissions after the dependency lock is final.
- [ ] Publish the approved privacy policy and place an accessible link in the
      app's genuine grown-up area before Kids-category submission.

## Change triggers that invalidate these notes

Repeat the full review if any release adds accounts, saved progress, cloud
backup, analytics, diagnostics upload, ads, purchases, web links, notifications,
user-entered text, microphone/camera/photos, location, social features, a new
SDK, or a dependency-version change that alters native behavior.

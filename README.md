# Smarter Heritage – Bhaktapur CV Guide

On-device monument recognition for Bhaktapur Durbar Square. Point the camera at **Nyatapola Temple** to identify it offline; browse other landmarks from the home screen.

**Stack:** Flutter · TensorFlow Lite · `camera` · `go_router`

---

## Features

- **Scanner** — Full-screen camera preview, gold heritage UI, shutter capture, on-device classification
- **Match panel** — Animated slide-up result sheet (detected / no match)
- **Monument detail** — History, images, and explore flow
- **Recents** — Recently viewed monuments (local storage)
- **Optional API** — Load monument list from a backend via `dart-define`

---

## Model

**`assets/models/nyatapola_student_v4.tflite`** — Knowledge-distilled student CNN (Nyatapola vs others).

| Property | Value |
|---|---|
| Input shape | `[1, 160, 160, 3]` float32, pixels `/ 255.0` |
| Output | `[1, 1]` sigmoid |
| Classes | `nyatapola_temple` (low raw ≈ 0) · `others` (high raw ≈ 1) |
| App threshold | **0.80** (tune in `app_constants.dart`) |

Only **Nyatapola Temple** is recognised by on-device CV today. Other landmarks are browse-only.

**Sigmoid mapping:** `P(nyatapola) = 1 - raw`, `P(others) = raw`. A match requires label `nyatapola_temple` and confidence ≥ threshold.

---

## App icon

Launcher icon source: `assets/icon/app_icon.png` (gold pagoda on dark heritage palette).

Regenerate all Android densities after changing the artwork:

```bash
dart run flutter_launcher_icons
```

---

## Quick start

**Requirements:** Flutter 3.44+ (stable), Android device or emulator with camera.

```bash
flutter pub get
flutter run
```

**Release build (device):**

```bash
flutter run --release
# or
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Optional: backend API

Offline mode uses built-in `MonumentRegistry` data. To load monuments from your server:

```bash
# Android emulator → host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Physical device → your LAN IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000

# Remote logging (dev only)
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=ENABLE_REMOTE_LOGGING=true
```

Cleartext HTTP is allowed in **debug** builds only (`android/app/src/debug/AndroidManifest.xml`).

### Permissions

- **Android:** `CAMERA` + `INTERNET` in `AndroidManifest.xml`; runtime camera permission when opening the scanner.
- **iOS:** Not included in this repo yet (Android-only).

---

## Scanner flow

1. Open scanner → request camera permission if needed → back camera preview.
2. Tap shutter → `takePicture()` JPEG.
3. Decode + resize in a background isolate (`classifier_preprocess.dart` via `compute`).
4. TFLite inference on the main isolate (interpreter is not isolate-safe).
5. If confident match → animated result sheet; else no-match panel.

If the model fails at startup, the scanner shows an error with **Retry**.

**UI notes:** Heritage top bar (compass → recents), bottom dock (Time-Travel → monument detail, sparkle → scan tips), gold corner brackets overlay.

---

## Project structure

```
lib/
├── main.dart
├── core/
│   ├── bootstrap/app_bootstrap.dart
│   ├── config/app_config.dart
│   ├── constants/app_constants.dart
│   ├── services/
│   │   ├── permission_service.dart
│   │   └── recents_service.dart
│   ├── theme/app_theme.dart
│   └── utils/
│       ├── app_router.dart
│       ├── classifier.dart
│       └── classifier_preprocess.dart
├── data/
│   ├── models/monument_model.dart
│   └── services/api_service.dart
└── features/
    ├── splash/
    ├── home/
    ├── scanner/
    │   ├── logic/scanner_cubit.dart
    │   └── presentation/
    │       ├── screens/scanner_screen.dart
    │       └── widgets/
    │           ├── scan_overlay_widget.dart
    │           ├── scanner_control_dock.dart
    │           ├── scanner_top_bar.dart
    │           ├── scanner_heritage_icons.dart
    │           ├── shutter_button.dart
    │           └── recents_sheet.dart
    └── monument_detail/

assets/
├── models/          # .tflite + labels.txt
└── images/monuments/

android/             # Android host (Kotlin DSL)
test/                # classifier_logic_test.dart
scripts/             # convert_model.py
```

---

## Tuning

| Parameter | File | Default |
|---|---|---|
| Confidence threshold | `lib/core/constants/app_constants.dart` | `0.80` |
| Pre-inference shutter delay | same | `600` ms |
| Model input size | same | `160` |
| Result sheet slide duration | `scanner_screen.dart` (`_kPanelSlideMs`) | `620` ms |

Lower threshold → more detections (more false positives). Raise threshold → stricter matching.

---

## Tests & analysis

```bash
flutter test
flutter analyze
```

---

## Android build notes

You may see **Kotlin Gradle Plugin (KGP) migration** warnings when building. They are informational for now; the app still builds. See [Flutter: migrate to built-in Kotlin](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) before a future Flutter release requires migration.

`android/local.properties` and Gradle caches are gitignored — run `flutter pub get` after clone.

---

## Roadmap

- [ ] Expand CV model to more landmarks
- [ ] Hard-negative training (screens, indoor clutter) to reduce false positives
- [ ] Time-Travel AR experience (UI placeholder wired to monument detail)
- [ ] Additional monument photos in `assets/images/monuments/`
- [ ] iOS platform support
- [ ] Release signing + HTTPS API for production

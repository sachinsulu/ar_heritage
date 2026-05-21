# Smarter Heritage – Bhaktapur CV Guide
### AR & Computer Vision guide for Bhaktapur Durbar Square

---

## Model

**`nyatapola_student_v4.tflite`** — Knowledge-distilled student CNN trained from the EfficientNetB0 v4 teacher.

| Property | Value |
|---|---|
| Architecture | 4× Conv blocks → GAP → BN → Dense(256) → Dense(64) → Dense(1, sigmoid) |
| Input shape | `[1, 160, 160, 3]`  float32  normalised `/ 255.0` |
| Output shape | `[1, 1]`  float32  sigmoid |
| Classes | `nyatapola_temple` (raw ≈ 0) · `others` (raw ≈ 1) |
| Threshold | 0.50 |
| File size | ~1.8 MB |

**Inference logic:**
- `raw ≤ 0.50` → `nyatapola_temple`, confidence = `1 - raw`
- `raw > 0.50` → `others`, confidence = `raw`

---

## Quick Start

### 1. Model is already included
The trained TFLite model is checked in at `assets/models/nyatapola_student_v4.tflite`.  
To retrain and replace it, use the notebook `nyatapola_student_distillation_v2.ipynb` on Google Colab
and run the convert script:

```bash
pip install tensorflow
python scripts/convert_model.py \
  --input  nyatapola_student_v3_best.keras \
  --output assets/models/nyatapola_student_v4.tflite
  # add --quant for INT8 quantisation (~4x smaller, minimal accuracy loss)
```

### 2. Labels file
`assets/models/labels.txt` must match the model's class order (line 0 = class 0):
```
nyatapola_temple
others
```

### 3. Add permissions (Android)
In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-feature android:name="android.hardware.camera" android:required="true"/>
```
And in the `<activity>` tag add: `android:hardwareAccelerated="true"`

For iOS add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera is needed to identify Bhaktapur monuments</string>
```

### 4. Install & run
```bash
flutter pub get
flutter run
```

---

## Project Structure
```
lib/
├── main.dart                          # Entry point, model init
├── core/
│   ├── constants/app_constants.dart   # Model path, class labels, thresholds
│   ├── theme/app_theme.dart           # Colors, fonts, Material theme
│   └── utils/
│       ├── classifier.dart            # TFLite inference wrapper
│       ├── motion_detector.dart       # Luma-plane motion detector (Lens-style)
│       └── app_router.dart            # go_router navigation
└── features/
    ├── home/                          # Landmark grid + scan CTA
    ├── scanner/
    │   ├── logic/scanner_cubit.dart   # State machine (idle/scanning/detected/noMatch)
    │   └── presentation/
    │       ├── screens/scanner_screen.dart
    │       └── widgets/
    │           ├── shutter_button.dart      # Google Lens-style shutter
    │           ├── scan_overlay_widget.dart # Static brackets, scan line on demand
    │           └── recents_sheet.dart
    └── monument_detail/               # Full info card with history

assets/
├── models/
│   ├── nyatapola_student_v4.tflite   # ← deployed model (1.8 MB)
│   └── labels.txt                    # class label order (must match model)
└── images/monuments/                 # reference images
```

---

## Tuning

| Parameter | File | Default | Notes |
|---|---|---|---|
| Confidence threshold | `app_constants.dart` | 0.50 | Lower = more detections, less precise |
| Auto-scan cooldown | `app_constants.dart` | 1200 ms | Still-scene dwell before auto-scan fires |
| Scan debounce | `app_constants.dart` | 3000 ms | Min gap between consecutive auto-scans |
| Motion threshold (MAD) | `app_constants.dart` | 8.0 | Lower = more sensitive to movement |
| Model input size | `app_constants.dart` | 160 | Must match model training size |

---

## Scanner Architecture (Lens-Style)

The scanner uses a **tap-to-scan** model instead of continuous frame inference:

1. Camera stream runs at full framerate — but **only** feeds the `MotionDetector`
2. `MotionDetector` does a 16×16 Y-plane thumbnail diff (~0.01 ms/frame)
3. When the scene is still for ≥8 frames (~267 ms), **or** the user taps the shutter:
   - Camera stream pauses
   - Single JPEG snapshot taken via `takePicture()`
   - Inference runs on a **background isolate** via `compute()`
   - Stream resumes
4. Result displayed with slide-up animation

---

## Next Steps
- [ ] Add `permission_handler` request flow on first launch
- [ ] Real monument images in `assets/images/monuments/`
- [ ] Expand model to cover all Bhaktapur Durbar Square landmarks
- [ ] "Time-Travel" before/after 2015 earthquake image comparison widget
- [ ] Firebase remote config for content updates
- [ ] Nepali language toggle (i18n)

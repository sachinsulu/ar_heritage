# Smarter Heritage – Bhaktapur CV Guide
### AR & Computer Vision guide for Bhaktapur Durbar Square

---

## Quick Start

### 1. Convert your model
```bash
pip install tensorflow
python scripts/convert_model.py \
  --input  path/to/your_model.h5 \
  --output assets/models/bhaktapur_model.tflite \
  --quant   # optional — reduces size ~4x with minimal accuracy loss
```

### 2. Verify label order
Open `assets/models/labels.txt` and ensure the class order matches
exactly what your model was trained on:
```
nyatapola_temple
55_window_palace
golden_gate
bhairavnath_temple
lions_gate
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
│       └── app_router.dart            # go_router navigation
└── data/
│   └── models/monument_model.dart    # Data + static landmark registry
└── features/
    ├── home/                          # Landmark grid + scan CTA
    ├── scanner/                       # Live camera + inference overlay
    └── monument_detail/               # Full info card with history

assets/
├── models/
│   ├── bhaktapur_model.tflite        # ← drop your converted model here
│   └── labels.txt                    # class label order
└── images/monuments/                 # reference images (add your own)
```

---

## Tuning

| Parameter | File | Default | Notes |
|---|---|---|---|
| Confidence threshold | `app_constants.dart` | 0.70 | Lower = more detections, less accurate |
| Frame skip | `app_constants.dart` | 10 | Higher = less CPU, slower response |
| Input size | `app_constants.dart` | 224 | Must match model training size |

---

## Next Steps (Sprint 2+)
- [ ] Add `permission_handler` request flow on first launch
- [ ] Real monument images in `assets/images/monuments/`
- [ ] "Time-Travel" before/after 2015 earthquake image comparison widget
- [ ] Lottie scan animation (replace custom painter)
- [ ] Firebase remote config for content updates
- [ ] Nepali language toggle (i18n)

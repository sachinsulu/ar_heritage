// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String modelPath  = 'assets/models/nyatapola_student_v2.tflite';
  static const String labelsPath = 'assets/models/labels.txt';

  /// Must match the input shape your model was trained on
  static const int modelInputSize = 128;

  /// Below this confidence we show "Point at a monument"
  static const double confidenceThreshold = 0.50;

  /// Must match labels.txt exactly (model outputs 2 classes)
  static const List<String> classLabels = [
    'nyatapola_temple',
    'others',
  ];

  // ── Lens-style scan constants ────────────────────────────────────────────

  /// Milliseconds the scene must be still before an auto-scan fires.
  static const int autoScanCooldownMs = 1200;

  /// Duration of the shutter-ring animation shown before inference starts.
  static const int scanAnimationMs = 600;

  /// Minimum milliseconds between two consecutive auto-scan attempts.
  static const int scanDebounceMs = 3000;

  /// Mean-absolute-difference threshold on the 16×16 luma thumbnail.
  /// Values below this mean the scene is considered still.
  static const double motionThreshold = 8.0;

  /// Number of consecutive still frames required before auto-scan fires.
  static const int stableFramesRequired = 8;
}

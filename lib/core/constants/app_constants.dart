// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String modelPath  = 'assets/models/bhaktapur_model.tflite';
  static const String labelsPath = 'assets/models/labels.txt';

  /// Must match the input shape your model was trained on
  static const int modelInputSize = 224;

  /// Below this confidence we show "Point at a monument"
  static const double confidenceThreshold = 0.70;

  static const List<String> classLabels = [
    'nyatapola_temple',
    '55_window_palace',
    'golden_gate',
    'bhairavnath_temple',
    'lions_gate',
  ];

  /// Run inference every N frames to save battery
  static const int inferenceFrameSkip = 30;
}

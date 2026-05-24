// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String modelPath  = 'assets/models/nyatapola_student_v4.tflite';
  static const String labelsPath = 'assets/models/labels.txt';

  /// Must match the input shape your model was trained on
  static const int modelInputSize = 160;

  /// Below this confidence we treat the scan as no match (reduces false positives).
  static const double confidenceThreshold = 0.80;

  /// Must match labels.txt exactly (model outputs 2 classes)
  static const List<String> classLabels = [
    'nyatapola_temple',
    'others',
  ];

  /// Monuments the on-device CV model can recognise today.
  static const Set<String> cvDetectableIds = {'nyatapola_temple'};

  /// Duration of the shutter-ring animation shown before inference starts.
  static const int scanAnimationMs = 600;
}


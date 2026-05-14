// lib/core/utils/classifier.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/app_constants.dart';

class ClassificationResult {
  final String label;
  final double confidence;
  const ClassificationResult({required this.label, required this.confidence});

  bool get isConfident => confidence >= AppConstants.confidenceThreshold;
}

class Classifier {
  Classifier._();
  static final Classifier instance = Classifier._();

  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> init() async {
    final labelData = await rootBundle.loadString(AppConstants.labelsPath);
    _labels = labelData
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
    debugPrint('[Classifier] Loaded — ${_labels.length} classes');
  }

  ClassificationResult? classify(Uint8List rawBytes) {
    if (_interpreter == null) return null;

    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return null;

    final resized = img.copyResize(
      decoded,
      width: AppConstants.modelInputSize,
      height: AppConstants.modelInputSize,
    );

    // Input tensor [1, 224, 224, 3] float32, normalised 0–1
    final inputBuffer = List.generate(
      1,
      (_) => List.generate(
        AppConstants.modelInputSize,
        (y) => List.generate(
          AppConstants.modelInputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          },
        ),
      ),
    );

    final outputBuffer =
        List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(inputBuffer, outputBuffer);

    final scores = List<double>.from(outputBuffer[0] as List);
    int maxIdx = 0;
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[maxIdx]) maxIdx = i;
    }

    return ClassificationResult(
      label: maxIdx < _labels.length ? _labels[maxIdx] : 'unknown',
      confidence: scores[maxIdx],
    );
  }

  void dispose() => _interpreter?.close();
}

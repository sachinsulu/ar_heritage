// lib/core/utils/classifier.dart
//
// Model: nyatapola_student_v4.tflite
// Architecture: 4× Conv blocks → GAP → BN → Dense(256) → Dense(64) → Dense(1, sigmoid)
// Input:  [1, 160, 160, 3]  float32  normalised to [0, 1]  (divide by 255)
// Output: [1, 1]            float32  sigmoid probability
//   • ~0.0  → nyatapola_temple   (confidence = 1 - raw)
//   • ~1.0  → others             (confidence = raw)
// Threshold: 0.50 (student trained with this threshold)

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_logger.dart';
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

  /// The v4 student model always outputs shape [1, 1] (single sigmoid).
  /// This flag is set after init() and guards _classifySigmoid path.
  bool _singleSigmoidOutput = false;
  int _outputSize = 1;

  DateTime _lastLog = DateTime(0); // throttle debug prints to 1/sec

  static const String _monumentLabel = 'nyatapola_temple';
  static const String _othersLabel   = 'others';

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      final labelData = await rootBundle.loadString(AppConstants.labelsPath);
      _labels = labelData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);

      final inputShape  = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      _outputSize = outputShape.isNotEmpty ? outputShape.last : 1;
      _singleSigmoidOutput = _outputSize == 1;

      AppLogger.log('[Classifier] Loaded: ${AppConstants.modelPath}');
      AppLogger.log('[Classifier] Input  shape : $inputShape');
      AppLogger.log('[Classifier] Output shape : $outputShape');
      AppLogger.log(
        '[Classifier] Mode: ${_singleSigmoidOutput ? "sigmoid [1,1]" : "softmax [1,$_outputSize]"}'
        '  labels: $_labels',
      );

      // Sanity-check: input must be [1, 160, 160, 3]
      if (inputShape.length != 4 ||
          inputShape[1] != AppConstants.modelInputSize ||
          inputShape[2] != AppConstants.modelInputSize ||
          inputShape[3] != 3) {
        AppLogger.log(
          '[Classifier] ⚠️  Unexpected input shape $inputShape. '
          'Expected [1, ${AppConstants.modelInputSize}, ${AppConstants.modelInputSize}, 3].',
        );
      }
    } catch (e, st) {
      AppLogger.log('[Classifier] Init failed: $e\n$st');
    }
  }

  // ── Classify a decoded image ──────────────────────────────────────────────

  /// Classify an already-decoded [img.Image].
  /// The image will be resized to [AppConstants.modelInputSize]×[AppConstants.modelInputSize].
  /// Preprocessing: divide each channel by 255.0 (matches notebook: img / 255.0).
  ClassificationResult? classifyImage(img.Image image) {
    if (_interpreter == null) return null;

    final int sz = AppConstants.modelInputSize;

    // Resize to model input size
    final resized = img.copyResize(image, width: sz, height: sz,
        interpolation: img.Interpolation.linear);

    // Build flat Float32List input: [1, 160, 160, 3]
    // Normalise: divide by 255.0  (notebook: img_128 = img_128 / 255.0)
    final inputFlat = Float32List(1 * sz * sz * 3);
    int idx = 0;
    for (var y = 0; y < sz; y++) {
      for (var x = 0; x < sz; x++) {
        final pixel = resized.getPixel(x, y);
        inputFlat[idx++] = pixel.r / 255.0;
        inputFlat[idx++] = pixel.g / 255.0;
        inputFlat[idx++] = pixel.b / 255.0;
      }
    }

    // Reshape to [1, 160, 160, 3] as nested List (tflite_flutter requirement)
    final inputBuffer = inputFlat.buffer.asFloat32List()
        .reshape([1, sz, sz, 3]);

    try {
      if (_singleSigmoidOutput) {
        return _classifySigmoid(inputBuffer);
      }
      return _classifySoftmax(inputBuffer);
    } catch (e, st) {
      AppLogger.log('[Classifier] Inference failed: $e\n$st');
      return null;
    }
  }

  // ── Sigmoid path (nyatapola_student_v4) ───────────────────────────────────

  /// Model output: single sigmoid float.
  ///   raw ≈ 0.0  →  nyatapola   (monumentScore = 1 - raw)
  ///   raw ≈ 1.0  →  others      (othersScore   = raw)
  /// Mirrors notebook predict_nyatapola():
  ///   label = 'others' if prob > threshold else 'nyatapola'
  ///   confidence = prob if others else (1 - prob)
  ClassificationResult _classifySigmoid(Object inputBuffer) {
    final outputBuffer = [
      [0.0]
    ]; // shape [1, 1]
    _interpreter!.run(inputBuffer, outputBuffer);

    final rawOutput =
        (outputBuffer[0][0] as num).toDouble().clamp(0.0, 1.0);

    // raw ~ 0 → nyatapola, raw ~ 1 → others
    final monumentScore = 1.0 - rawOutput; // P(nyatapola)
    final othersScore   = rawOutput;        // P(others)

    AppLogger.log(
      '[Classifier] rawOutput = $rawOutput, P(nyatapola) = ${(monumentScore * 100).toStringAsFixed(1)}%, P(others) = ${(othersScore * 100).toStringAsFixed(1)}%',
    );

    if (rawOutput <= (1.0 - AppConstants.confidenceThreshold)) {
      // i.e. monumentScore >= confidenceThreshold
      AppLogger.log(
        '[Classifier] ✓ DETECTED: $_monumentLabel  '
        '${(monumentScore * 100).toStringAsFixed(1)}%  raw=$rawOutput',
      );
      return ClassificationResult(
        label:      _monumentLabel,
        confidence: monumentScore,
      );
    }

    return ClassificationResult(label: _othersLabel, confidence: othersScore);
  }

  // ── Softmax path (fallback for other models) ──────────────────────────────

  ClassificationResult _classifySoftmax(Object inputBuffer) {
    final outputBuffer =
        List.filled(_outputSize, 0.0).reshape([1, _outputSize]);
    _interpreter!.run(inputBuffer, outputBuffer);

    final scores = List<double>.from(
      (outputBuffer[0] as List).map((v) => (v as num).toDouble()),
    );

    final monumentIdx  = _labels.indexOf(_monumentLabel);
    final monumentScore = (monumentIdx >= 0 && monumentIdx < scores.length)
        ? scores[monumentIdx]
        : scores.first;
    final othersScore = (scores.length > 1)
        ? scores.firstWhere((s) => s != monumentScore, orElse: () => 1.0 - monumentScore)
        : 1.0 - monumentScore;

    _logScores(monumentScore: monumentScore, othersScore: othersScore);

    if (monumentScore >= AppConstants.confidenceThreshold) {
      AppLogger.log(
        '[Classifier] ✓ DETECTED: $_monumentLabel  '
        '${(monumentScore * 100).toStringAsFixed(1)}%',
      );
      return ClassificationResult(
        label:      _monumentLabel,
        confidence: monumentScore,
      );
    }

    final maxIdx = scores.indexWhere(
      (s) => s == scores.reduce((a, b) => a > b ? a : b),
    );
    final label = (maxIdx >= 0 && maxIdx < _labels.length)
        ? _labels[maxIdx]
        : _othersLabel;
    return ClassificationResult(label: label, confidence: scores[maxIdx]);
  }

  // ── Classify raw image bytes (JPEG / PNG) ─────────────────────────────────

  /// Used by the cubit's isolate path: takes the raw bytes from [takePicture()].
  /// The [image] package honours EXIF orientation on decode — no manual
  /// rotation needed for camera-captured JPEGs.
  ClassificationResult? classify(Uint8List rawBytes) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      AppLogger.log('[Classifier] classify(): could not decode image bytes');
      return null;
    }
    // Bake the EXIF orientation into the physical image pixels so it is upright
    final oriented = img.bakeOrientation(decoded);
    AppLogger.log('[Classifier] classify(): decoded image size = ${oriented.width}x${oriented.height}');
    return classifyImage(oriented);
  }

  // ── Throttled debug logging ───────────────────────────────────────────────

  void _logScores({
    required double monumentScore,
    required double othersScore,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastLog).inMilliseconds <= 1000) return;
    _lastLog = now;
    AppLogger.log(
      '[Classifier] RAW → $_monumentLabel: ${(monumentScore * 100).toStringAsFixed(1)}%'
      '  |  $_othersLabel: ${(othersScore * 100).toStringAsFixed(1)}%',
    );
  }

  void dispose() => _interpreter?.close();
}

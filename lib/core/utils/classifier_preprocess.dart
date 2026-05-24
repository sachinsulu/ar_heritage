// lib/core/utils/classifier_preprocess.dart
//
// Image decode + resize runs in a background isolate via [compute].
// TFLite inference stays on the main isolate (interpreter is not isolate-safe).

import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../constants/app_constants.dart';

/// Decodes JPEG/PNG bytes and builds a normalised [1, H, W, 3] float tensor (flat).
Float32List? preprocessImageBytes(Uint8List rawBytes) {
  if (rawBytes.isEmpty) return null;

  final decoded = img.decodeImage(rawBytes);
  if (decoded == null) return null;

  final oriented = img.bakeOrientation(decoded);
  final int sz = AppConstants.modelInputSize;
  final resized = img.copyResize(
    oriented,
    width: sz,
    height: sz,
    interpolation: img.Interpolation.linear,
  );

  final inputFlat = Float32List(1 * sz * sz * 3);
  var idx = 0;
  for (var y = 0; y < sz; y++) {
    for (var x = 0; x < sz; x++) {
      final pixel = resized.getPixel(x, y);
      inputFlat[idx++] = pixel.r / 255.0;
      inputFlat[idx++] = pixel.g / 255.0;
      inputFlat[idx++] = pixel.b / 255.0;
    }
  }
  return inputFlat;
}

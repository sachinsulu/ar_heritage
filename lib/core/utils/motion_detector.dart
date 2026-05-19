// lib/core/utils/motion_detector.dart

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Lightweight motion detector that operates only on the Y (luma) plane of a
/// YUV420 camera frame. It downsamples to a 16×16 thumbnail and computes the
/// mean absolute difference (MAD) between consecutive frames.
///
/// When the scene is still for [AppConstants.stableFramesRequired] consecutive
/// frames, [onStable] is fired once. When motion is detected again, [onMotion]
/// is fired and the counter resets.
class MotionDetector {
  MotionDetector({
    required this.onStable,
    required this.onMotion,
  });

  final VoidCallback onStable;
  final VoidCallback onMotion;

  static const int _thumbSize = 16;
  static const int _thumbPixels = _thumbSize * _thumbSize; // 256

  Uint8List? _prevThumb;
  int _stableCount = 0;
  bool _stableFired = false;

  /// Call this from the camera image stream callback.
  /// It is intentionally synchronous and cheap (~0.01 ms per call).
  void processFrame(CameraImage frame) {
    if (frame.planes.isEmpty) return;

    final thumb = _buildLumaThumb(frame);
    if (thumb == null) return;

    final prev = _prevThumb;
    _prevThumb = thumb;

    if (prev == null) return; // first frame — no diff yet

    final mad = _meanAbsDiff(prev, thumb);

    if (mad > AppConstants.motionThreshold) {
      // Scene is moving
      if (_stableCount > 0 || _stableFired) {
        onMotion();
      }
      _stableCount = 0;
      _stableFired = false;
    } else {
      // Scene is still
      _stableCount++;
      if (_stableCount >= AppConstants.stableFramesRequired && !_stableFired) {
        _stableFired = true;
        onStable();
      }
    }
  }

  /// Resets state (call when a scan is triggered or the screen resumes).
  void reset() {
    _prevThumb = null;
    _stableCount = 0;
    _stableFired = false;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Builds a 16×16 luma thumbnail by nearest-neighbour subsampling the Y plane.
  Uint8List? _buildLumaThumb(CameraImage frame) {
    try {
      final yPlane = frame.planes[0];
      final yBytes = yPlane.bytes;
      final srcW = frame.width;
      final srcH = frame.height;
      final rowStride = yPlane.bytesPerRow;

      final thumb = Uint8List(_thumbPixels);
      final xStep = srcW / _thumbSize;
      final yStep = srcH / _thumbSize;

      for (var ty = 0; ty < _thumbSize; ty++) {
        final srcY = (ty * yStep).toInt().clamp(0, srcH - 1);
        for (var tx = 0; tx < _thumbSize; tx++) {
          final srcX = (tx * xStep).toInt().clamp(0, srcW - 1);
          final idx = srcY * rowStride + srcX;
          thumb[ty * _thumbSize + tx] =
              idx < yBytes.length ? yBytes[idx] : 0;
        }
      }
      return thumb;
    } catch (e) {
      debugPrint('[MotionDetector] thumb error: $e');
      return null;
    }
  }

  /// Mean absolute difference between two same-length luma buffers.
  double _meanAbsDiff(Uint8List a, Uint8List b) {
    var sum = 0;
    for (var i = 0; i < _thumbPixels; i++) {
      sum += (a[i] - b[i]).abs();
    }
    return sum / _thumbPixels;
  }
}

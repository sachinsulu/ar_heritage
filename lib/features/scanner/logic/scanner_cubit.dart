// lib/features/scanner/logic/scanner_cubit.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/classifier.dart';
import '../../../core/utils/motion_detector.dart';
import '../../../data/models/monument_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum ScannerStatus { idle, scanning, detected, noMatch }

class ScannerState {
  const ScannerState({
    this.status = ScannerStatus.idle,
    this.result,
    this.monument,
    this.autoScanEnabled = true,
  });

  final ScannerStatus status;
  final ClassificationResult? result;
  final MonumentModel? monument;
  final bool autoScanEnabled;

  bool get isIdle     => status == ScannerStatus.idle;
  bool get isScanning => status == ScannerStatus.scanning;
  bool get isDetected => status == ScannerStatus.detected;
  bool get isNoMatch  => status == ScannerStatus.noMatch;

  ScannerState copyWith({
    ScannerStatus? status,
    ClassificationResult? result,
    MonumentModel? monument,
    bool clearResult = false,
    bool? autoScanEnabled,
  }) {
    return ScannerState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      monument: clearResult ? null : monument ?? this.monument,
      autoScanEnabled: autoScanEnabled ?? this.autoScanEnabled,
    );
  }
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// A lightweight state-machine that drives the Google-Lens-style scanner.
///
/// Usage:
/// ```dart
/// final cubit = ScannerCubit();
/// await cubit.init();                // sets up camera + motion detector
/// cubit.triggerScan();               // tap-to-scan
/// cubit.clearResult();               // dismiss result card
/// cubit.toggleAutoScan();            // enable/disable auto-scan
/// cubit.dispose();                   // must call on screen dispose
/// ```
class ScannerCubit extends ChangeNotifier {
  ScannerState _state = const ScannerState();
  ScannerState get state => _state;

  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  late final MotionDetector _motionDetector;

  bool _scanLocked = false;   // prevents re-entrant scans
  DateTime _lastScanTime = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Initialise ──────────────────────────────────────────────────────────────

  Future<void> init() async {
    _motionDetector = MotionDetector(
      onStable: _onSceneStable,
      onMotion: _onSceneMotion,
    );

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      _cameraController!.startImageStream(_onCameraFrame);
      notifyListeners();
    } catch (e) {
      debugPrint('[ScannerCubit] Camera init failed: $e');
    }
  }

  // ── Camera frame handler (cheap — motion detect only) ────────────────────

  void _onCameraFrame(CameraImage frame) {
    // Only feed motion detector. Zero inference happens here.
    if (_state.isIdle && _state.autoScanEnabled) {
      _motionDetector.processFrame(frame);
    }
  }

  // ── Motion detector callbacks ─────────────────────────────────────────────

  void _onSceneStable() {
    if (!_state.autoScanEnabled) return;
    if (_state.isDetected) return; // already showing a result
    final debounce = Duration(milliseconds: AppConstants.scanDebounceMs);
    if (DateTime.now().difference(_lastScanTime) < debounce) return;
    triggerScan(auto: true);
  }

  void _onSceneMotion() {
    // If we were showing a no-match, clear it when the user moves the camera
    if (_state.isNoMatch) {
      _emit(_state.copyWith(status: ScannerStatus.idle, clearResult: true));
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Trigger a single-shot scan. Called on shutter tap or auto-stable callback.
  Future<void> triggerScan({bool auto = false}) async {
    if (_scanLocked) return;
    if (_state.isScanning) return;
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    _scanLocked = true;
    _lastScanTime = DateTime.now();
    _motionDetector.reset();

    _emit(_state.copyWith(status: ScannerStatus.scanning, clearResult: true));

    // Brief animation window before inference
    await Future.delayed(
      Duration(milliseconds: AppConstants.scanAnimationMs),
    );

    try {
      // Pause stream → take a single JPEG snapshot → resume stream
      await ctrl.stopImageStream();
      final XFile file = await ctrl.takePicture();
      final Uint8List bytes = await file.readAsBytes();

      // Run inference on the main thread — tflite_flutter's Interpreter uses
      // native FFI handles that cannot cross isolate boundaries, so compute()
      // would see an uninitialised Classifier (null _interpreter → null result).
      // The student-v2 model is tiny (128×128 input) so inference is ~5–20 ms.
      final ClassificationResult? result =
          Classifier.instance.classify(bytes);

      if (result == null) {
        _emit(_state.copyWith(
          status: ScannerStatus.noMatch,
          clearResult: true,
        ));
        return;
      }

      if (result.isConfident) {
        final monument = MonumentRegistry.findById(result.label);
        _emit(_state.copyWith(
          status: ScannerStatus.detected,
          result: result,
          monument: monument,
        ));
      } else {
        _emit(_state.copyWith(
          status: ScannerStatus.noMatch,
          result: result,
          clearResult: false,
        ));
      }
    } catch (e) {
      debugPrint('[ScannerCubit] Scan error: $e');
      _emit(_state.copyWith(
        status: ScannerStatus.noMatch,
        clearResult: true,
      ));
    } finally {
      // Resume stream (ignore errors if controller was disposed)
      try {
        final c = _cameraController;
        if (c != null && c.value.isInitialized && !c.value.isStreamingImages) {
          c.startImageStream(_onCameraFrame);
        }
      } catch (_) {}
      _scanLocked = false;
    }
  }

  /// Dismiss the result card and return to idle.
  void clearResult() {
    _motionDetector.reset();
    _emit(_state.copyWith(status: ScannerStatus.idle, clearResult: true));
  }

  /// Toggle auto-scan on/off.
  void toggleAutoScan() {
    _motionDetector.reset();
    _emit(_state.copyWith(autoScanEnabled: !_state.autoScanEnabled));
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void handleAppResumed() {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (!ctrl.value.isStreamingImages) {
      ctrl.startImageStream(_onCameraFrame);
    }
    _motionDetector.reset();
  }

  void handleAppInactive() {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (ctrl.value.isStreamingImages) {
      ctrl.stopImageStream();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _emit(ScannerState newState) {
    _state = newState;
    notifyListeners();
  }
}



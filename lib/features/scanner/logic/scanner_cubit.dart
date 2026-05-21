// lib/features/scanner/logic/scanner_cubit.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/classifier.dart';
import '../../../data/models/monument_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum ScannerStatus { idle, scanning, detected, noMatch }

class ScannerState {
  const ScannerState({
    this.status = ScannerStatus.idle,
    this.result,
    this.monument,
  });

  final ScannerStatus status;
  final ClassificationResult? result;
  final MonumentModel? monument;

  bool get isIdle     => status == ScannerStatus.idle;
  bool get isScanning => status == ScannerStatus.scanning;
  bool get isDetected => status == ScannerStatus.detected;
  bool get isNoMatch  => status == ScannerStatus.noMatch;

  ScannerState copyWith({
    ScannerStatus? status,
    ClassificationResult? result,
    MonumentModel? monument,
    bool clearResult = false,
  }) {
    return ScannerState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      monument: clearResult ? null : monument ?? this.monument,
    );
  }
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// A lightweight state-machine that drives the camera photo-capture classification.
class ScannerCubit extends ChangeNotifier {
  ScannerState _state = const ScannerState();
  ScannerState get state => _state;

  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  bool _scanLocked = false;   // prevents re-entrant scans

  // ── Initialise ──────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      notifyListeners();
    } catch (e) {
      debugPrint('[ScannerCubit] Camera init failed: $e');
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Trigger a single-shot picture capture and classification.
  Future<void> triggerScan() async {
    if (_scanLocked) return;
    if (_state.isScanning) return;
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    _scanLocked = true;
    _emit(_state.copyWith(status: ScannerStatus.scanning, clearResult: true));

    // Brief animation window before capture & inference
    await Future.delayed(
      Duration(milliseconds: AppConstants.scanAnimationMs),
    );

    try {
      // Capture direct high-quality JPEG snapshot
      final XFile file = await ctrl.takePicture();
      final Uint8List bytes = await file.readAsBytes();

      // Run inference on the captured picture bytes
      final ClassificationResult? result =
          Classifier.instance.classify(bytes);

      if (result == null) {
        _emit(_state.copyWith(
          status: ScannerStatus.noMatch,
          clearResult: true,
        ));
        return;
      }

      // Check confidence and filter out 'others' category
      if (result.isConfident && result.label != 'others') {
        final monument = MonumentRegistry.findById(result.label);
        if (monument != null) {
          _emit(_state.copyWith(
            status: ScannerStatus.detected,
            result: result,
            monument: monument,
          ));
          return;
        }
      }

      _emit(_state.copyWith(
        status: ScannerStatus.noMatch,
        result: result,
        clearResult: false,
      ));
    } catch (e) {
      debugPrint('[ScannerCubit] Scan error: $e');
      _emit(_state.copyWith(
        status: ScannerStatus.noMatch,
        clearResult: true,
      ));
    } finally {
      _scanLocked = false;
    }
  }

  /// Dismiss the result card and return to idle.
  void clearResult() {
    _emit(_state.copyWith(status: ScannerStatus.idle, clearResult: true));
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void handleAppResumed() {
    // Standard camera controllers handle resume natively, but we notify listeners to be safe
    notifyListeners();
  }

  void handleAppInactive() {
    // No-op
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

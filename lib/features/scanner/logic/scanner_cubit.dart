// lib/features/scanner/logic/scanner_cubit.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, compute, debugPrint;
import 'package:flutter/services.dart';

import '../../../core/bootstrap/app_bootstrap.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/classifier.dart';
import '../../../core/utils/classifier_preprocess.dart';
import '../../../data/models/monument_model.dart';

// ── Camera setup ──────────────────────────────────────────────────────────────

enum CameraSetupPhase {
  checkingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  initializing,
  ready,
  noCamera,
  cameraError,
}

// ── Scan state ────────────────────────────────────────────────────────────────

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

class ScannerCubit extends ChangeNotifier {
  ScannerState _state = const ScannerState();
  ScannerState get state => _state;

  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  CameraSetupPhase _cameraPhase = CameraSetupPhase.checkingPermission;
  CameraSetupPhase get cameraPhase => _cameraPhase;

  bool _scanLocked = false;

  bool get classifierReady => AppBootstrap.classifierReady;
  String? get classifierError => AppBootstrap.classifierError;

  // ── Permission + camera ───────────────────────────────────────────────────

  Future<void> requestPermissionAndInit() async {
    _setCameraPhase(CameraSetupPhase.checkingPermission);

    final outcome = await PermissionService.instance.requestCamera();
    switch (outcome) {
      case CameraPermissionOutcome.granted:
        await _initCamera();
      case CameraPermissionOutcome.denied:
        _setCameraPhase(CameraSetupPhase.permissionDenied);
      case CameraPermissionOutcome.permanentlyDenied:
        _setCameraPhase(CameraSetupPhase.permissionPermanentlyDenied);
    }
  }

  Future<void> retryPermission() => requestPermissionAndInit();

  Future<void> openAppSettings() => PermissionService.instance.openSettings();

  Future<void> _initCamera() async {
    _setCameraPhase(CameraSetupPhase.initializing);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setCameraPhase(CameraSetupPhase.noCamera);
        return;
      }

      await _cameraController?.dispose();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _setCameraPhase(CameraSetupPhase.ready);
    } catch (e) {
      debugPrint('[ScannerCubit] Camera init failed: $e');
      _setCameraPhase(CameraSetupPhase.cameraError);
    }
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  Future<void> triggerScan() async {
    if (!classifierReady) return;
    if (_scanLocked) return;
    if (_state.isScanning) return;
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    _scanLocked = true;
    _emit(_state.copyWith(status: ScannerStatus.scanning, clearResult: true));

    await Future.delayed(
      Duration(milliseconds: AppConstants.scanAnimationMs),
    );

    try {
      final XFile file = await ctrl.takePicture();
      final Uint8List bytes = await file.readAsBytes();

      final inputFlat = await compute(preprocessImageBytes, bytes);
      if (inputFlat == null) {
        _emit(_state.copyWith(
          status: ScannerStatus.noMatch,
          clearResult: true,
        ));
        return;
      }

      final ClassificationResult? result =
          Classifier.instance.classifyFromTensor(inputFlat);

      if (result == null) {
        _emit(_state.copyWith(
          status: ScannerStatus.noMatch,
          clearResult: true,
        ));
        return;
      }

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

  void clearResult() {
    _emit(_state.copyWith(status: ScannerStatus.idle, clearResult: true));
  }

  Future<void> retryClassifier() async {
    final ok = await Classifier.instance.init();
    AppBootstrap.classifierReady = ok;
    AppBootstrap.classifierError =
        ok ? null : Classifier.instance.initError;
    notifyListeners();
  }

  void handleAppResumed() {
    if (_cameraPhase == CameraSetupPhase.permissionDenied ||
        _cameraPhase == CameraSetupPhase.permissionPermanentlyDenied) {
      requestPermissionAndInit();
      return;
    }
    notifyListeners();
  }

  void handleAppInactive() {}

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _setCameraPhase(CameraSetupPhase phase) {
    _cameraPhase = phase;
    notifyListeners();
  }

  void _emit(ScannerState newState) {
    _state = newState;
    notifyListeners();
  }
}

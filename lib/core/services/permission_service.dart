// lib/core/services/permission_service.dart

import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionOutcome {
  granted,
  denied,
  permanentlyDenied,
}

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  Future<CameraPermissionOutcome> requestCamera() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return CameraPermissionOutcome.granted;
    }

    if (status.isPermanentlyDenied) {
      return CameraPermissionOutcome.permanentlyDenied;
    }

    final result = await Permission.camera.request();
    if (result.isGranted) return CameraPermissionOutcome.granted;
    if (result.isPermanentlyDenied) {
      return CameraPermissionOutcome.permanentlyDenied;
    }
    return CameraPermissionOutcome.denied;
  }

  Future<void> openSettings() => openAppSettings();
}

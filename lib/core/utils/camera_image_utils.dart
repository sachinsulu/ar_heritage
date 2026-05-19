// lib/core/utils/camera_image_utils.dart

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Converts a live [CameraImage] frame to RGB for the TFLite classifier.
class CameraImageUtils {
  CameraImageUtils._();

  static img.Image? toRgbImage(
    CameraImage cameraImage,
    CameraDescription camera,
  ) {
    img.Image? image;
    final format = cameraImage.format.group;

    switch (format) {
      case ImageFormatGroup.yuv420:
      case ImageFormatGroup.nv21:
        image = _fromYuv420(cameraImage);
        break;
      case ImageFormatGroup.bgra8888:
        image = _fromBgra8888(cameraImage);
        break;
      case ImageFormatGroup.jpeg:
        image = img.decodeJpg(_concatenatePlanes(cameraImage));
        break;
      default:
        debugPrint('[CameraImageUtils] Unsupported format: $format');
        return null;
    }

    if (image == null) return null;
    return _applySensorRotation(image, camera.sensorOrientation);
  }

  static Uint8List _concatenatePlanes(CameraImage image) {
    final builder = BytesBuilder(copy: false);
    for (final plane in image.planes) {
      builder.add(plane.bytes);
    }
    return builder.toBytes();
  }

  static img.Image? _fromBgra8888(CameraImage cameraImage) {
    final plane = cameraImage.planes.first;
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: plane.bytes.buffer,
      bytesOffset: plane.bytes.offsetInBytes,
      rowStride: plane.bytesPerRow,
      order: img.ChannelOrder.bgra,
    );
  }

  static img.Image? _fromYuv420(CameraImage cameraImage) {
    if (cameraImage.planes.length < 3) return null;

    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final out = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      final yRow = y * yPlane.bytesPerRow;
      final uvRow = (y >> 1) * uPlane.bytesPerRow;

      for (var x = 0; x < width; x++) {
        final yIndex = yRow + x;
        final uvIndex = uvRow + (x >> 1);

        final yVal = yPlane.bytes[yIndex];
        final uVal = uPlane.bytes[uvIndex];
        final vVal = vPlane.bytes[uvIndex];

        final r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
        final g =
            (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
                .round()
                .clamp(0, 255);
        final b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }

  static img.Image _applySensorRotation(img.Image image, int sensorOrientation) {
    if (sensorOrientation == 0) return image;
    return img.copyRotate(image, angle: sensorOrientation);
  }
}

// lib/core/utils/app_logger.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../data/services/api_service.dart';
import '../config/app_config.dart';

class AppLogger {
  AppLogger._();

  static void log(String message) {
    debugPrint(message);

    if (AppConfig.remoteLoggingEnabled) {
      final uri = Uri.parse('${ApiService.baseUrl}/logs');
      http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .catchError((e) => http.Response('error', 500));
    }

    if (message.contains('[Classifier]')) {
      _writeToLocalLog(message);
    }
  }

  static Future<void> _writeToLocalLog(String message) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/classifier.log');
      final timestamp = DateTime.now()
          .toIso8601String()
          .substring(0, 19)
          .replaceFirst('T', ' ');
      await file.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('Failed to write to local classifier.log: $e');
    }
  }
}

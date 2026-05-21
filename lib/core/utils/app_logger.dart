// lib/core/utils/app_logger.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/services/api_service.dart';

class AppLogger {
  AppLogger._();

  /// Logs a message to the console and sends it to the central server log file.
  static void log(String message) {
    // 1. Standard console print
    debugPrint(message);

    // 2. Asynchronous API post to save into detect_log.txt
    final uri = Uri.parse('${ApiService.baseUrl}/logs');
    http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    ).catchError((e) {
      // Fail silently to prevent crashing during network interruptions
      return http.Response('error', 500);
    });
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/monument_model.dart';
import '../../core/utils/app_logger.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS/Desktop
  // Note: If testing on a physical device, use your machine's local IP (e.g. 192.168.x.x)
  static const String baseUrl = 'http://192.168.101.4:8000';

  Future<List<MonumentModel>> getMonuments() async {
    final url = Uri.parse('$baseUrl/monuments');
    AppLogger.log('DEBUG: API Request -> GET $url');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      AppLogger.log('DEBUG: API Response [${response.statusCode}] for /monuments');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MonumentModel.fromJson(json)).toList();
      } else {
        AppLogger.log('DEBUG: API Error Body: ${response.body}');
        throw Exception('Failed to load monuments: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.log('DEBUG: API Exception in getMonuments: $e');
      rethrow;
    }
  }

  Future<MonumentModel> getMonumentDetail(String id) async {
    final url = Uri.parse('$baseUrl/monuments/$id');
    AppLogger.log('DEBUG: API Request -> GET $url');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      AppLogger.log('DEBUG: API Response [${response.statusCode}] for /monuments/$id');
      
      if (response.statusCode == 200) {
        return MonumentModel.fromJson(jsonDecode(response.body));
      } else {
        AppLogger.log('DEBUG: API Error Body: ${response.body}');
        throw Exception('Failed to load monument detail: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.log('DEBUG: API Exception in getMonumentDetail: $e');
      rethrow;
    }
  }
}

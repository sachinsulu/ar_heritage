import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/monument_model.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/app_logger.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  Future<List<MonumentModel>> getMonuments() async {
    if (!AppConfig.hasApi) {
      throw Exception('API_BASE_URL not configured');
    }
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
    if (!AppConfig.hasApi) {
      throw Exception('API_BASE_URL not configured');
    }
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

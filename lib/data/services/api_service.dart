import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/monument_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<List<MonumentModel>> getMonuments() async {
    final response = await http.get(Uri.parse('$baseUrl/monuments'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MonumentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load monuments');
    }
  }

  Future<MonumentModel> getMonumentDetail(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/monuments/$id'));
    if (response.statusCode == 200) {
      return MonumentModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load monument detail');
    }
  }
}

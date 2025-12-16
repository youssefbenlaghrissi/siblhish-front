import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // Méthode générique pour les requêtes GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = '${ApiConfig.baseUrl}$endpoint';
      debugPrint('🌐 API GET: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ API Error: $e');
      debugPrint('❌ URL attempted: $url');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      throw Exception('Network error: $e');
    }
  }

  // Méthode générique pour les requêtes POST
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Méthode générique pour les requêtes PUT
  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Méthode générique pour les requêtes DELETE
  static Future<void> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}


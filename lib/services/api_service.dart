import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // Méthode générique pour les requêtes GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    try {
      debugPrint('🌐 API GET: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      throw Exception('Network error: $e');
    }
  }

  // Méthode générique pour les requêtes POST
  static Future<Map<String, dynamic>> post(
      String endpoint, dynamic body) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    try {
      debugPrint('🌐 API POST: $url');
      
      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      throw Exception('Network error: $e');
    }
  }

  // Méthode générique pour les requêtes PUT
  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    try {
      debugPrint('🌐 API PUT: $url');
      
      final response = await http
          .put(
            Uri.parse(url),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      throw Exception('Network error: $e');
    }
  }

  // Méthode générique pour les requêtes PATCH
  static Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> body) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    try {
      debugPrint('🌐 API PATCH: $url');
      
      final response = await http
          .patch(
            Uri.parse(url),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isEmpty) {
          return {'status': 'success', 'data': null};
        }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to patch data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      throw Exception('Network error: $e');
    }
  }

  // Méthode générique pour les requêtes DELETE
  static Future<void> delete(String endpoint, [dynamic body]) async {
    final url = '${ApiConfig.baseUrl}$endpoint';
    try {
      debugPrint('🌐 API DELETE: $url');
      
      final request = http.Request('DELETE', Uri.parse(url));
      request.headers.addAll(ApiConfig.defaultHeaders);
      if (body != null) {
        request.body = json.encode(body);
      }
      
      final response = await request.send().timeout(ApiConfig.timeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete data: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      throw Exception('Network error: $e');
    }
  }
}


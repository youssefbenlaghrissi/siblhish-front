import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  /// Extrait le message d'erreur du JSON retourné par le backend
  /// Le backend retourne toujours: {"status":"error","message":"...","data":null,"errors":null}
  static String? _extractErrorMessage(String responseBody) {
    try {
      final errorBody = json.decode(responseBody) as Map<String, dynamic>;
      return errorBody['message'] as String?;
    } catch (_) {
      // Si le parsing JSON échoue, essayer d'extraire le message avec regex
      try {
        final messageMatch = RegExp(r'"message"\s*:\s*"([^"]*)"').firstMatch(responseBody);
        return messageMatch?.group(1);
      } catch (_) {
        return null;
      }
    }
  }

  /// Lance une exception avec le message d'erreur du backend ou un message par défaut
  static Never _throwBackendError(String responseBody, String defaultMessage) {
    final errorMessage = _extractErrorMessage(responseBody);
    if (errorMessage != null && errorMessage.isNotEmpty) {
      throw Exception(errorMessage);
    }
    throw Exception(defaultMessage);
  }
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
        _throwBackendError(response.body, 'Erreur lors du chargement des données');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      // Si c'est déjà une Exception avec le message du backend, la relancer
      if (e is Exception && !e.toString().contains('Network error')) {
        rethrow;
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
        _throwBackendError(response.body, 'Erreur lors de la création');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      // Si c'est déjà une Exception avec le message du backend, la relancer
      if (e is Exception && !e.toString().contains('Network error')) {
        rethrow;
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
      debugPrint('📦 Body: ${json.encode(body)}');
      
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
        _throwBackendError(response.body, 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      // Si c'est déjà une Exception avec le message du backend, la relancer
      if (e is Exception && !e.toString().contains('Network error')) {
        rethrow;
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
      debugPrint('📦 Body: ${json.encode(body)}');
      
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
        _throwBackendError(response.body, 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      // Si c'est déjà une Exception avec le message du backend, la relancer
      if (e is Exception && !e.toString().contains('Network error')) {
        rethrow;
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
        _throwBackendError(responseBody, 'Erreur lors de la suppression');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout: Le serveur ne répond pas. Vérifiez que le backend est démarré et accessible.');
      }
      // Si c'est déjà une Exception avec le message du backend, la relancer directement
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }
}


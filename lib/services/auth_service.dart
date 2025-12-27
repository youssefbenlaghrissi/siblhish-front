import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

  // Google Sign In
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '179520798738-v4aqvqf3lsr3eo09lkkmho6bpfr6ee6h.apps.googleusercontent.com',
  );

  // ==================== Google Sign In ====================

  /// Connexion avec Google
  /// 1. Authentification Google SDK
  /// 2. Envoi au backend pour créer/récupérer l'utilisateur en BDD
  /// 3. Sauvegarde de la session localement
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google Sign In...');
      
      // Vérifier d'abord si l'utilisateur est déjà connecté silencieusement
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // Si pas de session silencieuse, demander une nouvelle authentification
      if (googleUser == null) {
        debugPrint('📝 Aucune session silencieuse, demande d\'authentification...');
        googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          return null;
        }
      } else {
      }
      
      // Ne pas nettoyer la session précédente si l'utilisateur est déjà connecté
      // Cela permet de préserver la session entre les ouvertures de l'app


      // 2. Envoyer au backend pour créer/récupérer l'utilisateur
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/social'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'provider': 'google',
          'email': googleUser.email,
          'displayName': googleUser.displayName ?? googleUser.email.split('@').first,
          'photoUrl': googleUser.photoUrl,
        }),
      ).timeout(ApiConfig.timeout);


      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parser seulement le début du JSON (avant les relations circulaires)
        // Extraire les champs essentiels avec regex
        final body = response.body;
        
        final idMatch = RegExp(r'"id":(\d+)').firstMatch(body);
        final firstNameMatch = RegExp(r'"firstName":"([^"]*)"').firstMatch(body);
        final lastNameMatch = RegExp(r'"lastName":"([^"]*)"').firstMatch(body);
        final emailMatch = RegExp(r'"email":"([^"]*)"').firstMatch(body);
        
        final userData = {
          'id': idMatch?.group(1) ?? '1',
          'firstName': firstNameMatch?.group(1) ?? 'User',
          'lastName': lastNameMatch?.group(1) ?? '',
          'email': emailMatch?.group(1) ?? googleUser.email,
        };
        
        // Sauvegarder la session localement
        await _saveUserData(userData);
        
        return userData;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Logout ====================

  /// Déconnexion complète
  /// 1. Déconnexion Google SDK
  /// 2. Suppression de la session locale
  static Future<void> logout() async {
    try {
      debugPrint('🔓 Starting logout...');
      
      // 1. Déconnexion Google SDK
      await _googleSignIn.signOut();
      
      // 2. Supprimer la session locale
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_userDataKey);
      
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Session Management ====================

  /// Sauvegarder les données utilisateur localement
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userId = userData['id']?.toString();
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
    
    await prefs.setString(_userDataKey, json.encode(userData));
    debugPrint('💾 Session saved: userId=$userId');
  }

  /// Récupérer l'ID utilisateur de la session
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Récupérer les données utilisateur de la session
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    if (userData != null) {
      return json.decode(userData) as Map<String, dynamic>;
    }
    return null;
  }

  /// Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null && userId.isNotEmpty;
  }
}

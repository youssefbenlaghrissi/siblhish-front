import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
      // D'abord, essayer de restaurer la session silencieusement
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // Si pas de session silencieuse, demander à l'utilisateur
      if (googleUser == null) {
        googleUser = await _googleSignIn.signIn();
      }
      
      if (googleUser == null) {
        return null;
      }

      // Demander les permissions de notifications (après le login)
      bool notificationsEnabled = false;
      try {
        final firebaseMessaging = FirebaseMessaging.instance;
        final currentSettings = await firebaseMessaging.getNotificationSettings();
        
        if (currentSettings.authorizationStatus == AuthorizationStatus.notDetermined) {
          // Première fois : demander les permissions
          debugPrint('📱 Demande de permissions de notifications après login...');
          final settings = await firebaseMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
          notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized ||
                               settings.authorizationStatus == AuthorizationStatus.provisional;
          debugPrint('📱 Permissions notifications: ${notificationsEnabled ? "accordées" : "refusées"}');
        } else {
          // Permissions déjà demandées : utiliser le statut actuel
          notificationsEnabled = currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
                               currentSettings.authorizationStatus == AuthorizationStatus.provisional;
          debugPrint('📱 Permissions notifications (déjà demandées): ${notificationsEnabled ? "accordées" : "refusées"}');
        }
      } catch (e) {
        debugPrint('⚠️ Erreur lors de la demande de permissions: $e');
        notificationsEnabled = false;
      }

      // Envoyer au backend pour créer/récupérer l'utilisateur avec notificationsEnabled
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/social'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'provider': 'google',
          'email': googleUser.email,
          'displayName': googleUser.displayName ?? googleUser.email.split('@').first,
          'photoUrl': googleUser.photoUrl,
          'notificationsEnabled': notificationsEnabled,
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
        // Extraire notificationsEnabled depuis la réponse (le backend retourne le statut réel de la DB)
        final notificationsEnabledMatch = RegExp(r'"notificationsEnabled":(true|false)').firstMatch(body);
        final notificationsEnabledFromDB = notificationsEnabledMatch?.group(1) == 'true';
        
        final userData = {
          'id': idMatch?.group(1) ?? '1',
          'firstName': firstNameMatch?.group(1) ?? 'User',
          'lastName': lastNameMatch?.group(1) ?? '',
          'email': emailMatch?.group(1) ?? googleUser.email,
          'notificationsEnabled': notificationsEnabledFromDB, // Utiliser le statut retourné par le backend
        };
        
        // Sauvegarder la session localement
        await _saveUserData(userData);
        
        return userData;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on PlatformException catch (e) {
      // Gestion spécifique des erreurs Google Sign-In
      String errorMessage = 'Erreur de connexion Google';
      
      // Log détaillé pour le débogage
      debugPrint('❌ Erreur Google Sign-In - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}');
      
      if (e.code == 'sign_in_failed') {
        errorMessage = 'Échec de la connexion Google.\n\n'
            'Il faut créer un OAuth Client Android dans Google Cloud Console:\n'
            '1. Allez sur Google Cloud Console → APIs & Services → Credentials\n'
            '2. Cliquez sur "+ CREATE CREDENTIALS" → "OAuth client ID"\n'
            '3. Type: "Android"\n'
            '4. Package name: ma.siblhish\n'
            '5. SHA-1: 63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84\n'
            '6. Créez et attendez 2-5 minutes\n\n'
            'Voir docs/CREER_OAUTH_CLIENT_ANDROID.md pour les instructions détaillées.';
      } else if (e.code == 'network_error') {
        errorMessage = 'Erreur réseau. Vérifiez votre connexion internet.';
      } else if (e.message != null && (e.message!.contains('10') || e.message!.contains('DEVELOPER_ERROR'))) {
        errorMessage = 'Configuration Google Sign-In incorrecte.\n\n'
            'Il faut créer un OAuth Client Android dans Google Cloud Console:\n'
            '1. Google Cloud Console → APIs & Services → Credentials\n'
            '2. "+ CREATE CREDENTIALS" → "OAuth client ID"\n'
            '3. Type: "Android", Package: ma.siblhish\n'
            '4. SHA-1: 63:3D:D0:8F:A9:29:88:39:C8:86:DC:62:B0:3B:70:6D:DC:AC:F6:84\n\n'
            'Voir docs/CREER_OAUTH_CLIENT_ANDROID.md pour les instructions complètes.';
      } else if (e.message != null && e.message!.contains('12500')) {
        errorMessage = 'Connexion annulée par l\'utilisateur.';
      } else {
        errorMessage = 'Erreur Google Sign-In: ${e.message ?? e.code}\n\n'
            'Code: ${e.code}\n'
            'Détails: ${e.details ?? "Aucun"}';
      }
      
      throw Exception(errorMessage);
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
  /// Vérifie d'abord la session locale, puis essaie de restaurer la session Google
  static Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    if (userId != null && userId.isNotEmpty) {
      // Vérifier si la session Google est toujours valide
      try {
        final currentUser = await _googleSignIn.signInSilently();
        if (currentUser != null) {
          return true;
        }
        // Si la session Google n'est plus valide, on garde quand même la session locale
        // L'utilisateur devra se reconnecter si nécessaire
        return true;
      } catch (e) {
        // Si erreur, on garde la session locale
        return true;
      }
    }
    return false;
  }

  /// Restaurer la session Google silencieusement
  /// Utilisé au démarrage de l'app pour reconnecter automatiquement
  static Future<bool> restoreGoogleSession() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        // Vérifier si on a déjà une session locale
        final userId = await getCurrentUserId();
        if (userId != null && userId.isNotEmpty) {
          // Session restaurée avec succès
          return true;
        }
        // Si pas de session locale, on doit reconnecter au backend
        // Mais on ne le fait pas automatiquement pour éviter les appels inutiles
        return false;
      }
      return false;
    } catch (e) {
      // Erreur silencieuse - l'utilisateur devra se reconnecter
      return false;
    }
  }
}

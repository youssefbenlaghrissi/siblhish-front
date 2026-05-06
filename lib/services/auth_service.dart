import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;

/// Exception spécifique pour les comptes créés via OAuth
class OAuthAccountException implements Exception {
  final String message;
  OAuthAccountException(this.message);
  
  @override
  String toString() => message;
}

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
      // Demander directement à l'utilisateur de sélectionner un compte
      // Ne pas utiliser signInSilently() pour éviter de restaurer un compte supprimé
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // Si l'utilisateur annule la sélection, retourner null
      if (googleUser == null) {
        debugPrint('📱 Connexion Google annulée par l\'utilisateur');
        return null;
      }
      
      debugPrint('📱 Compte Google sélectionné: ${googleUser.email}');

      // Demander les permissions de notifications (après le login)
      // Pour Google Sign-In, on ne sait pas si c'est un nouvel utilisateur ou existant
      // Le backend gère ça : si utilisateur existant, il garde le statut existant
      // On demande seulement si notDetermined (première fois jamais)
      // Si denied, on ne demande pas (pour éviter de demander à un utilisateur existant)
      bool notificationsEnabled = false;
      try {
        final firebaseMessaging = FirebaseMessaging.instance;
        final currentSettings = await firebaseMessaging.getNotificationSettings();
        
        if (currentSettings.authorizationStatus == AuthorizationStatus.notDetermined) {
          // Première fois jamais : demander les permissions
          debugPrint('📱 Demande de permissions de notifications après login Google (première fois)...');
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
          // Permissions déjà demandées (authorized, denied, ou provisional)
          // Pour un utilisateur existant, le backend utilisera le statut de la DB
          // Pour un nouvel utilisateur avec denied, le backend utilisera la valeur envoyée
          notificationsEnabled = currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
                               currentSettings.authorizationStatus == AuthorizationStatus.provisional;
          debugPrint('📱 Permissions notifications (statut actuel): ${notificationsEnabled ? "accordées" : "refusées"}');
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
        // Vérifier d'abord si la réponse contient une erreur (cas où le backend retourne 200 avec un message d'erreur)
        try {
          final responseBody = json.decode(response.body) as Map<String, dynamic>;
          if (responseBody['status'] == 'error' && responseBody['message'] != null) {
            final errorMessage = responseBody['message'] as String;
            debugPrint('❌ Backend retourne une erreur dans un 200: $errorMessage');
            
            // Si le compte a été supprimé, déconnecter le compte Google pour éviter qu'il soit restauré automatiquement
            if (errorMessage.toLowerCase().contains('supprimé') || 
                errorMessage.toLowerCase().contains('supprime')) {
              debugPrint('🔓 Déconnexion du compte Google supprimé');
              try {
                await _googleSignIn.signOut();
              } catch (e) {
                debugPrint('⚠️ Erreur lors de la déconnexion Google: $e');
              }
            }
            
            throw Exception(errorMessage);
          }
        } catch (e) {
          // Si c'est déjà une Exception avec le message du backend, la relancer
          if (e is Exception && !e.toString().contains('FormatException')) {
            rethrow;
          }
          // Si le parsing échoue, continuer avec le parsing normal
        }
        
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
        // Le backend retourne toujours une structure JSON standardisée:
        // { "status": "error", "message": "...", "data": null, "errors": null }
        // Faire confiance au backend : utiliser directement son message
        debugPrint('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        
        String? errorMessage;
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = errorBody['message'] as String?;
          debugPrint('📝 Message d\'erreur extrait du backend: $errorMessage');
        } catch (e) {
          debugPrint('❌ Erreur lors du parsing JSON: $e');
          // Si le parsing JSON échoue, errorMessage reste null
        }
        
        // Si on a un message d'erreur du backend, le lancer directement
        if (errorMessage != null && errorMessage.isNotEmpty) {
          debugPrint('✅ Lancement de l\'exception avec le message du backend: $errorMessage');
          
          // Si le compte a été supprimé, déconnecter le compte Google pour éviter qu'il soit restauré automatiquement
          if (errorMessage.toLowerCase().contains('supprimé') || 
              errorMessage.toLowerCase().contains('supprime')) {
            debugPrint('🔓 Déconnexion du compte Google supprimé');
            try {
              await _googleSignIn.signOut();
            } catch (e) {
              debugPrint('⚠️ Erreur lors de la déconnexion Google: $e');
            }
          }
          
          throw Exception(errorMessage);
        }
        
        // Fallback seulement si le parsing JSON échoue complètement
        debugPrint('⚠️ Aucun message d\'erreur trouvé, utilisation du fallback');
        throw Exception('Erreur lors de la connexion');
      }
    } on SocketException catch (e) {
      // Erreur de connexion (backend arrêté ou inaccessible)
      debugPrint('❌ Erreur de connexion: $e');
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.');
    } on TimeoutException catch (e) {
      // Timeout réseau
      debugPrint('❌ Timeout: $e');
      throw Exception('Le serveur met trop de temps à répondre. Vérifiez votre connexion internet et réessayez.');
    } on http.ClientException catch (e) {
      // Erreur client HTTP (connexion refusée, etc.)
      debugPrint('❌ Erreur client HTTP: $e');
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.');
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
            '4. Package name: ma.siblhish.app\n'
            '5. SHA-1 (debug et release) : keytool -list -v -keystore <votre-keystore> -alias <alias>\n'
            '6. Créez et attendez 2-5 minutes\n\n'
            'Voir docs/CREER_OAUTH_CLIENT_ANDROID.md pour les instructions détaillées.';
      } else if (e.code == 'network_error') {
        errorMessage = 'Erreur réseau. Vérifiez votre connexion internet.';
      } else if (e.message != null && (e.message!.contains('10') || e.message!.contains('DEVELOPER_ERROR'))) {
        errorMessage = 'Configuration Google Sign-In incorrecte.\n\n'
            'Il faut créer un OAuth Client Android dans Google Cloud Console:\n'
            '1. Google Cloud Console → APIs & Services → Credentials\n'
            '2. "+ CREATE CREDENTIALS" → "OAuth client ID"\n'
            '3. Type: "Android", Package: ma.siblhish.app\n'
            '4. SHA-1 (debug et release) : keytool -list -v -keystore <votre-keystore> -alias <alias>\n\n'
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
      // Si c'est déjà une Exception avec le message du backend, la relancer directement
      if (e is Exception) {
        rethrow;
      }
      // Sinon, créer une exception générique
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la connexion: ${e.toString()}');
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

  // ==================== Register/Login avec Email/Password ====================

  /// Créer un compte avec email et mot de passe
  /// 1. Demander les permissions de notifications
  /// 2. Envoyer au backend pour créer l'utilisateur
  /// 3. Sauvegarder la session localement
  static Future<Map<String, dynamic>?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String language = 'fr',
  }) async {
    try {
      // Demander les permissions de notifications (après le register)
      // Pour un nouvel utilisateur, on demande toujours les permissions, même si elles ont été refusées précédemment
      bool notificationsEnabled = false;
      try {
        final firebaseMessaging = FirebaseMessaging.instance;
        final currentSettings = await firebaseMessaging.getNotificationSettings();
        
        // Pour un nouvel utilisateur, toujours demander les permissions
        // (même si elles ont été refusées précédemment après désinstallation)
        if (currentSettings.authorizationStatus == AuthorizationStatus.notDetermined ||
            currentSettings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint('📱 Demande de permissions de notifications après register...');
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
          // Déjà autorisées ou provisoires
          notificationsEnabled = currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
                               currentSettings.authorizationStatus == AuthorizationStatus.provisional;
          debugPrint('📱 Permissions notifications (déjà accordées): ${notificationsEnabled ? "accordées" : "refusées"}');
        }
      } catch (e) {
        debugPrint('⚠️ Erreur lors de la demande de permissions: $e');
        notificationsEnabled = false;
      }

      // Envoyer au backend pour créer l'utilisateur
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'language': language,
          'notificationsEnabled': notificationsEnabled,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parser la réponse (même méthode que pour Google Sign-In)
        final body = response.body;
        
        final idMatch = RegExp(r'"id":(\d+)').firstMatch(body);
        final firstNameMatch = RegExp(r'"firstName":"([^"]*)"').firstMatch(body);
        final lastNameMatch = RegExp(r'"lastName":"([^"]*)"').firstMatch(body);
        final emailMatch = RegExp(r'"email":"([^"]*)"').firstMatch(body);
        final notificationsEnabledMatch = RegExp(r'"notificationsEnabled":(true|false)').firstMatch(body);
        final notificationsEnabledFromDB = notificationsEnabledMatch?.group(1) == 'true';
        
        final userData = {
          'id': idMatch?.group(1) ?? '1',
          'firstName': firstNameMatch?.group(1) ?? firstName,
          'lastName': lastNameMatch?.group(1) ?? lastName,
          'email': emailMatch?.group(1) ?? email,
          'notificationsEnabled': notificationsEnabledFromDB,
        };
        
        // Sauvegarder la session localement
        await _saveUserData(userData);
        
        return userData;
      } else {
        // Le backend retourne toujours une structure JSON standardisée:
        // { "status": "error", "message": "...", "data": null, "errors": null }
        // Faire confiance au backend : utiliser directement son message
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorBody['message'] as String?;
          
          if (errorMessage != null && errorMessage.isNotEmpty) {
            throw Exception(errorMessage);
          }
        } catch (e) {
          // Si c'est déjà une Exception avec le message du backend, la relancer
          if (e is Exception && !e.toString().contains('FormatException')) {
            rethrow;
          }
        }
        
        // Fallback seulement si le parsing JSON échoue complètement
        throw Exception('Erreur lors de la création du compte');
      }
    } on SocketException catch (e) {
      // Erreur de connexion (backend arrêté ou inaccessible)
      debugPrint('❌ Erreur de connexion: $e');
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.');
    } on TimeoutException catch (e) {
      // Timeout réseau
      debugPrint('❌ Timeout: $e');
      throw Exception('Le serveur met trop de temps à répondre. Vérifiez votre connexion internet et réessayez.');
    } on http.ClientException catch (e) {
      // Erreur client HTTP (connexion refusée, etc.)
      debugPrint('❌ Erreur client HTTP: $e');
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.');
    } catch (e) {
      // Si c'est déjà une Exception avec un message, la relancer
      if (e is Exception) {
        rethrow;
      }
      // Sinon, créer une exception générique
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la création du compte: ${e.toString()}');
    }
  }

  /// Connexion avec email et mot de passe
  /// 1. Envoyer au backend pour authentifier
  /// 2. Sauvegarder la session localement
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Envoyer au backend pour authentifier
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // Parser la réponse (même méthode que pour Google Sign-In)
        final body = response.body;
        
        final idMatch = RegExp(r'"id":(\d+)').firstMatch(body);
        final firstNameMatch = RegExp(r'"firstName":"([^"]*)"').firstMatch(body);
        final lastNameMatch = RegExp(r'"lastName":"([^"]*)"').firstMatch(body);
        final emailMatch = RegExp(r'"email":"([^"]*)"').firstMatch(body);
        final notificationsEnabledMatch = RegExp(r'"notificationsEnabled":(true|false)').firstMatch(body);
        final notificationsEnabledFromDB = notificationsEnabledMatch?.group(1) == 'true';
        
        final userData = {
          'id': idMatch?.group(1) ?? '1',
          'firstName': firstNameMatch?.group(1) ?? 'User',
          'lastName': lastNameMatch?.group(1) ?? '',
          'email': emailMatch?.group(1) ?? email,
          'notificationsEnabled': notificationsEnabledFromDB,
        };
        
        // Sauvegarder la session localement
        await _saveUserData(userData);
        
        return userData;
      } else {
        // Le backend retourne toujours une structure JSON standardisée:
        // { "status": "error", "message": "...", "data": null, "errors": null }
        // Faire confiance au backend : utiliser directement son message
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorBody['message'] as String?;
          
          if (errorMessage != null && errorMessage.isNotEmpty) {
            // Détecter si c'est un compte OAuth (exception spéciale pour l'UI)
            final errorMsgLower = errorMessage.toLowerCase();
            if (errorMsgLower.contains('connexion sociale') || 
                errorMsgLower.contains('utiliser la connexion google')) {
              throw OAuthAccountException(errorMessage);
            }
            
            // Pour tous les autres cas, faire confiance au message du backend
            throw Exception(errorMessage);
          }
        } catch (e) {
          // Si c'est déjà une OAuthAccountException, la relancer
          if (e is OAuthAccountException) {
            rethrow;
          }
          // Si c'est déjà une Exception avec le message du backend, la relancer
          if (e is Exception && !e.toString().contains('FormatException')) {
            rethrow;
          }
        }
        
        // Fallback seulement si le parsing JSON échoue complètement
        throw Exception('Erreur lors de la connexion');
      }
    } on SocketException catch (e) {
      // Erreur de connexion (backend arrêté ou inaccessible)
      debugPrint('❌ Erreur de connexion: $e');
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.');
    } on TimeoutException catch (e) {
      // Timeout réseau
      debugPrint('❌ Timeout: $e');
      throw Exception('Le serveur met trop de temps à répondre. Vérifiez votre connexion internet et réessayez.');
    } on http.ClientException catch (e) {
      // Erreur client HTTP (connexion refusée, etc.)
      debugPrint('❌ Erreur client HTTP: $e');
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.');
    } catch (e) {
      // Si c'est déjà une Exception avec un message, la relancer
      if (e is Exception) {
        rethrow;
      }
      // Sinon, créer une exception générique
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la connexion: ${e.toString()}');
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;

/// Utilitaire pour formater les messages d'erreur de manière compréhensible pour l'utilisateur
class ErrorMessageFormatter {
  /// Formate un message d'erreur technique en message compréhensible pour l'utilisateur
  static String formatErrorMessage(dynamic error) {
    if (error == null) {
      return 'Une erreur inattendue s\'est produite.';
    }

    final errorString = error.toString();

    // PRIORITÉ 1 : Vérifier d'abord les codes HTTP (même si "Network error" est dans le message)
    // Erreur 500 (serveur) - Vérifier AVANT "Network error" car le message peut contenir les deux
    if (errorString.contains('500')) {
      // Essayer d'extraire le message du JSON si disponible
      // Chercher le JSON même s'il y a "Network error" dans le message
      try {
        // Chercher le JSON avec un pattern plus large pour capturer tout le JSON
        final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(errorString);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(0)!;
          final jsonData = json.decode(jsonString);
          if (jsonData is Map && jsonData['message'] != null) {
            final backendMessage = jsonData['message'] as String;
            
            // Messages spécifiques du backend
            if (backendMessage.contains('User not found')) {
              return 'Votre compte n\'a pas été trouvé. Veuillez vous reconnecter.';
            }
            if (backendMessage.contains('not found')) {
              return 'Les données demandées n\'ont pas été trouvées.';
            }
            if (backendMessage.contains('Unauthorized') || backendMessage.contains('Forbidden')) {
              return 'Vous n\'êtes pas autorisé à effectuer cette action. Veuillez vous reconnecter.';
            }
            
            // Retourner le message du backend si compréhensible
            return backendMessage;
          }
        }
      } catch (e) {
        // Si le parsing JSON échoue, continuer avec le traitement par défaut
        debugPrint('⚠️ Erreur parsing JSON dans ErrorMessageFormatter: $e');
      }
      
      return 'Une erreur s\'est produite sur le serveur. Veuillez réessayer plus tard.';
    }

    // Erreur 404 (non trouvé)
    if (errorString.contains('404')) {
      return 'La ressource demandée n\'a pas été trouvée.';
    }

    // Erreur 401 (non autorisé)
    if (errorString.contains('401') || errorString.contains('Unauthorized')) {
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    }

    // Erreur 403 (interdit)
    if (errorString.contains('403') || errorString.contains('Forbidden')) {
      return 'Vous n\'êtes pas autorisé à effectuer cette action.';
    }

    // Erreur 400 (mauvaise requête)
    if (errorString.contains('400')) {
      return 'Les données envoyées sont incorrectes. Veuillez vérifier et réessayer.';
    }

    // PRIORITÉ 2 : Erreurs réseau (seulement si pas de code HTTP détecté)
    if (errorString.contains('Network error') || 
        errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('Connection refused')) {
      return 'Problème de connexion internet. Veuillez vérifier votre connexion et réessayer.';
    }

    // Timeout
    if (errorString.contains('Timeout') || errorString.contains('timeout')) {
      return 'Le serveur met trop de temps à répondre. Veuillez réessayer.';
    }

    // Erreur de format JSON
    if (errorString.contains('FormatException') || errorString.contains('json')) {
      return 'Erreur de format de données. Veuillez réessayer.';
    }

    // Message générique pour les autres erreurs
    return 'Une erreur s\'est produite. Veuillez réessayer.';
  }

  /// Retourne un titre approprié selon le type d'erreur
  static String getErrorTitle(dynamic error) {
    if (error == null) {
      return 'Erreur';
    }

    final errorString = error.toString();

    if (errorString.contains('Network error') || 
        errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup')) {
      return 'Erreur de connexion';
    }

    if (errorString.contains('401') || errorString.contains('Unauthorized')) {
      return 'Session expirée';
    }

    if (errorString.contains('500')) {
      return 'Erreur serveur';
    }

    return 'Erreur';
  }
}


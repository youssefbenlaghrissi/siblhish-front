import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _balanceDataKey = 'balance_data';
  static const String _balanceUserIdKey = 'balance_user_id';

  /// Sauvegarder les données de balance pour un utilisateur
  static Future<void> saveBalanceData(String userId, Map<String, dynamic> balanceData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_balanceDataKey, json.encode(balanceData));
      await prefs.setString(_balanceUserIdKey, userId);
    } catch (e) {
      // Ignorer les erreurs de stockage
    }
  }

  /// Récupérer les données de balance pour un utilisateur
  static Future<Map<String, dynamic>?> getBalanceData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(_balanceUserIdKey);
      
      // Vérifier que les données correspondent à l'utilisateur actuel
      if (savedUserId != userId) {
        return null;
      }
      
      final balanceDataJson = prefs.getString(_balanceDataKey);
      if (balanceDataJson != null) {
        return json.decode(balanceDataJson) as Map<String, dynamic>;
      }
    } catch (e) {
      // En cas d'erreur, retourner null
    }
    return null;
  }

  /// Supprimer les données de balance (lors de la déconnexion)
  static Future<void> clearBalanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_balanceDataKey);
      await prefs.remove(_balanceUserIdKey);
    } catch (e) {
      // Ignorer les erreurs de stockage
    }
  }
}


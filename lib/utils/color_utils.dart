import 'package:flutter/material.dart';

/// Utilitaires pour la gestion des couleurs
class ColorUtils {
  /// Parser une couleur depuis une chaîne hexadécimale
  /// Format accepté: "#RRGGBB" ou "RRGGBB"
  /// Retourne Colors.grey en cas d'erreur
  static Color parseColor(String colorString) {
    try {
      // Supprimer le # s'il existe
      final hexColor = colorString.replaceFirst('#', '');
      // Ajouter 0xFF pour l'opacité complète
      return Color(int.parse('0xFF$hexColor'));
    } catch (e) {
      return Colors.grey;
    }
  }
}


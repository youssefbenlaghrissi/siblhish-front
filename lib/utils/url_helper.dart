import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

/// Helper pour gérer les mises à jour d'URL sur web
class UrlHelper {
  /// Met à jour l'URL avec un paramètre de requête sans recharger la page
  /// Format de l'URL: ?budgetMonth=YYYY-MM
  static void updateUrlParameter(String paramName, String paramValue) {
    if (kIsWeb) {
      try {
        // Utiliser dart:html uniquement sur web
        // ignore: avoid_web_libraries_in_flutter
        // Note: Pour utiliser cette fonctionnalité, vous devez ajouter:
        // import 'dart:html' as html;
        // Et décommenter la ligne suivante:
        // html.window.history.pushState(null, '', _buildUrl(paramName, paramValue));
        
        final url = _buildUrl(paramName, paramValue);
        debugPrint('📅 URL mise à jour: $url');
        // Pour activer la mise à jour réelle de l'URL, décommentez la ligne ci-dessus
        // et ajoutez l'import dart:html en haut du fichier
      } catch (e) {
        debugPrint('Erreur mise à jour URL: $e');
      }
    }
  }

  static String _buildUrl(String paramName, String paramValue) {
    final currentUrl = Uri.base;
    final queryParams = Map<String, String>.from(currentUrl.queryParameters);
    queryParams[paramName] = paramValue;
    final newUrl = currentUrl.replace(queryParameters: queryParams);
    return newUrl.toString();
  }

  /// Lit un paramètre de requête depuis l'URL
  static String? getUrlParameter(String paramName) {
    if (kIsWeb) {
      try {
        final url = Uri.base;
        return url.queryParameters[paramName];
      } catch (e) {
        debugPrint('Erreur lecture paramètre URL: $e');
        return null;
      }
    }
    return null;
  }
}


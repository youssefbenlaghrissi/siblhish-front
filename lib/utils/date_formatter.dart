import 'package:intl/intl.dart';

/// Utilitaires pour le formatage des dates
class DateFormatter {
  /// Formateur pour les dates au format "dd MMM yyyy" (ex: "20 déc. 2025")
  static final _dateFormatter = DateFormat('dd MMM yyyy', 'fr');

  /// Formater une date au format "dd MMM yyyy"
  /// Exemple: DateTime(2025, 12, 20) -> "20 déc. 2025"
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Formater une date au format "dd/MM/yyyy"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr').format(date);
  }

  /// Formater une date au format "dd MMM" (sans année)
  /// Exemple: DateTime(2025, 12, 20) -> "20 déc."
  static String formatDateWithoutYear(DateTime date) {
    return DateFormat('dd MMM', 'fr').format(date);
  }
}


import 'package:intl/intl.dart';

/// Utilitaires pour le formatage des montants en devise
class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    symbol: 'MAD ',
    decimalDigits: 2,
  );

  /// Formater un montant en devise MAD
  /// Exemple: 1000.5 -> "MAD 1,000.50"
  static String format(double amount) {
    return _formatter.format(amount);
  }

  /// Formater un montant avec préfixe + ou -
  /// Exemple: 1000.5 -> "+MAD 1,000.50" ou -1000.5 -> "-MAD 1,000.50"
  static String formatWithSign(double amount, {bool isIncome = false}) {
    final sign = isIncome ? '+' : '-';
    return '$sign${format(amount)}';
  }
}


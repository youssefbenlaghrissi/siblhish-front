import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/statistics_card.dart';
import '../../models/statistics.dart';
import '../../models/expense.dart';
import '../../providers/budget_provider.dart';
import '../../theme/app_theme.dart';

/// Fonction utilitaire centralisée pour formater la période analysée
/// Retourne le libellé formaté de la période (ex: "Période analysée : janvier 2026")
String formatPeriodLabel(String period, DateTime selectedDate) {
  switch (period) {
    case 'daily':
      return 'Période analysée : ${DateFormat('d MMMM yyyy', 'fr').format(selectedDate)}';
    case 'weekly':
      final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      String weekRange;
      if (startOfWeek.month == endOfWeek.month && startOfWeek.year == endOfWeek.year) {
        weekRange = '${startOfWeek.day}-${endOfWeek.day} ${DateFormat('MMMM yyyy', 'fr').format(startOfWeek)}';
      } else {
        weekRange = '${DateFormat('d MMM', 'fr').format(startOfWeek)} - ${DateFormat('d MMM yyyy', 'fr').format(endOfWeek)}';
      }
      return 'Période analysée : $weekRange';
    case 'monthly':
      return 'Période analysée : ${DateFormat('MMMM yyyy', 'fr').format(selectedDate)}';
    default:
      return 'Période analysée : ${DateFormat('MMMM yyyy', 'fr').format(selectedDate)}';
  }
}

/// Widget pour la carte Moyenne Dépenses
class AverageExpenseCardWidget extends StatelessWidget {
  final double averageExpense;
  final String period; // "daily", "weekly", "monthly"
  final int numberOfPeriods; // Nombre réel de périodes avec données
  final DateTime selectedDate; // Date sélectionnée pour formater la période

  const AverageExpenseCardWidget({
    super.key,
    required this.averageExpense,
    required this.period,
    this.numberOfPeriods = 0,
    required this.selectedDate,
  });

  String _getPeriodLabel(String period, int numberOfPeriods) {
    switch (period) {
      case 'day':
        return 'Moyenne quotidienne (30 derniers jours)';
      case 'month':
        if (numberOfPeriods > 0) {
          return 'Moyenne mensuelle ($numberOfPeriods ${numberOfPeriods == 1 ? 'mois' : 'mois'})';
        }
        return 'Moyenne mensuelle';
      case 'year':
        if (numberOfPeriods > 0) {
          return 'Moyenne annuelle ($numberOfPeriods ${numberOfPeriods == 1 ? 'année' : 'années'})';
        }
        return 'Moyenne annuelle';
      default:
        return 'Moyenne mensuelle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                StatisticsCardType.averageExpenseCard.icon,
                color: AppTheme.expenseColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  StatisticsCardType.averageExpenseCard.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.help_outline_rounded,
                  size: 20,
                  color: Colors.blue,
                ),
                onPressed: () => _showAverageExpenseInfoDialog(context, averageExpense, period, numberOfPeriods, selectedDate),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatter.format(averageExpense),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.expenseColor,
            ),
          ),
          const SizedBox(height: 12),
          // Période analysée
          Text(
            formatPeriodLabel(period, selectedDate),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAverageExpenseInfoDialog(BuildContext context, double averageExpense, String period, int numberOfPeriods, DateTime selectedDate) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    String calculationExplanation = '';
    
    switch (period) {
      case 'daily':
        calculationExplanation = 'Cette valeur représente le total des dépenses pour le jour sélectionné. Comme il s\'agit d\'un seul jour, la "moyenne" correspond au total des dépenses de cette journée.';
        break;
      case 'weekly':
        calculationExplanation = 'La moyenne est calculée en divisant le total des dépenses de la semaine par le nombre réel de jours dans la semaine (7 jours). Cette moyenne représente vos dépenses quotidiennes moyennes sur la semaine.';
        break;
      case 'monthly':
        calculationExplanation = 'La moyenne est calculée en divisant le total des dépenses du mois par le nombre réel de jours dans le mois (28 à 31 jours selon le mois). Cette moyenne représente vos dépenses quotidiennes moyennes sur le mois.';
        break;
      default:
        calculationExplanation = 'La moyenne est calculée en divisant le total des dépenses par le nombre réel de périodes dans la plage de dates sélectionnée.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              StatisticsCardType.averageExpenseCard.icon,
              color: AppTheme.expenseColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                StatisticsCardType.averageExpenseCard.title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cette carte affiche la moyenne de vos dépenses sur la période sélectionnée.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Période analysée
              Text(
                formatPeriodLabel(period, selectedDate),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Calcul
              Text(
                calculationExplanation,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Moyenne actuelle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.expenseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.expenseColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Moyenne actuelle',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      formatter.format(averageExpense),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.expenseColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(
                color: AppTheme.expenseColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour la carte Moyenne Revenus
class AverageIncomeCardWidget extends StatelessWidget {
  final double averageIncome;
  final String period; // "daily", "weekly", "monthly"
  final int numberOfPeriods; // Nombre réel de périodes avec données
  final DateTime selectedDate; // Date sélectionnée pour formater la période

  const AverageIncomeCardWidget({
    super.key,
    required this.averageIncome,
    required this.period,
    this.numberOfPeriods = 0,
    required this.selectedDate,
  });

  String _getPeriodLabel(String period, int numberOfPeriods) {
    switch (period) {
      case 'day':
        return 'Moyenne quotidienne (30 derniers jours)';
      case 'month':
        if (numberOfPeriods > 0) {
          return 'Moyenne mensuelle ($numberOfPeriods ${numberOfPeriods == 1 ? 'mois' : 'mois'})';
        }
        return 'Moyenne mensuelle';
      case 'year':
        if (numberOfPeriods > 0) {
          return 'Moyenne annuelle ($numberOfPeriods ${numberOfPeriods == 1 ? 'année' : 'années'})';
        }
        return 'Moyenne annuelle';
      default:
        return 'Moyenne mensuelle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                StatisticsCardType.averageIncomeCard.icon,
                color: AppTheme.incomeColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  StatisticsCardType.averageIncomeCard.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.help_outline_rounded,
                  size: 20,
                  color: Colors.blue,
                ),
                onPressed: () => _showAverageIncomeInfoDialog(context, averageIncome, period, numberOfPeriods, selectedDate),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatter.format(averageIncome),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.incomeColor,
            ),
          ),
          const SizedBox(height: 12),
          // Période analysée
          Text(
            formatPeriodLabel(period, selectedDate),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAverageIncomeInfoDialog(BuildContext context, double averageIncome, String period, int numberOfPeriods, DateTime selectedDate) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    String calculationExplanation = '';
    
    switch (period) {
      case 'daily':
        calculationExplanation = 'Cette valeur représente le total des revenus pour le jour sélectionné. Comme il s\'agit d\'un seul jour, la "moyenne" correspond au total des revenus de cette journée.';
        break;
      case 'weekly':
        calculationExplanation = 'La moyenne est calculée en divisant le total des revenus de la semaine par le nombre réel de jours dans la semaine (7 jours). Cette moyenne représente vos revenus quotidiens moyens sur la semaine.';
        break;
      case 'monthly':
        calculationExplanation = 'La moyenne est calculée en divisant le total des revenus du mois par le nombre réel de jours dans le mois (28 à 31 jours selon le mois). Cette moyenne représente vos revenus quotidiens moyens sur le mois.';
        break;
      default:
        calculationExplanation = 'La moyenne est calculée en divisant le total des revenus par le nombre réel de périodes dans la plage de dates sélectionnée.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              StatisticsCardType.averageIncomeCard.icon,
              color: AppTheme.incomeColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                StatisticsCardType.averageIncomeCard.title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cette carte affiche la moyenne de vos revenus sur la période sélectionnée.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Période analysée
              Text(
                formatPeriodLabel(period, selectedDate),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Calcul
              Text(
                calculationExplanation,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Moyenne actuelle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.incomeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.incomeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Moyenne actuelle',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      formatter.format(averageIncome),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.incomeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(
                color: AppTheme.incomeColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour la carte Nombre de Transactions
class TransactionCountCardWidget extends StatelessWidget {
  final int incomeCount;
  final int expenseCount;
  final String? period; // Période sélectionnée (optionnel)
  final DateTime? selectedDate; // Date sélectionnée (optionnel)

  const TransactionCountCardWidget({
    super.key,
    required this.incomeCount,
    required this.expenseCount,
    this.period,
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = incomeCount + expenseCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                StatisticsCardType.transactionCountCard.icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  StatisticsCardType.transactionCountCard.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Détails : Revenus et Dépenses
          Row(
            children: [
              Expanded(
                child: _TransactionDetailItem(
                  label: 'Revenus',
                  count: incomeCount,
                  color: AppTheme.incomeColor,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TransactionDetailItem(
                  label: 'Dépenses',
                  count: expenseCount,
                  color: AppTheme.expenseColor,
                  icon: Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionDetailItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _TransactionDetailItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de base pour les cartes statistiques
class _BaseCardWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _BaseCardWidget({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/statistics_card.dart';
import '../../models/statistics.dart';
import '../../models/expense.dart';
import '../../providers/budget_provider.dart';
import '../../theme/app_theme.dart';

/// Widget pour la carte Solde Actuel
class BalanceCardWidget extends StatelessWidget {
  final double balance;

  const BalanceCardWidget({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);

    return _BaseCardWidget(
      title: StatisticsCardType.balanceCard.title,
      icon: StatisticsCardType.balanceCard.icon,
      color: balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
      child: Text(
        formatter.format(balance),
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
        ),
      ),
    );
  }
}

/// Widget pour la carte Économies
class SavingsCardWidget extends StatelessWidget {
  final double savings;
  final String period; // "day", "month", ou "year"

  const SavingsCardWidget({
    super.key,
    required this.savings,
    this.period = 'month',
  });

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'day':
        return 'Les 30 derniers jours';
      case 'month':
        return 'Les 12 derniers mois';
      case 'year':
        return 'Toutes les années';
      default:
        return 'Les 12 derniers mois';
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
                StatisticsCardType.savingsCard.icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  StatisticsCardType.savingsCard.title,
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
                onPressed: () => _showSavingsInfoDialog(context, savings, period),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatter.format(savings),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showSavingsInfoDialog(BuildContext context, double savings, String period) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    String periodLabel = '';
    String explanation = '';
    
    switch (period) {
      case 'daily':
        periodLabel = 'Jour sélectionné';
        explanation = 'Cette valeur représente la somme totale des économies (balance) pour le jour sélectionné. Les économies sont calculées comme la différence entre les revenus et les dépenses pour cette journée.';
        break;
      case 'weekly':
        periodLabel = 'Semaine sélectionnée';
        explanation = 'Cette valeur représente la somme totale des économies (balance) pour la semaine sélectionnée. Les économies sont calculées comme la différence entre les revenus et les dépenses pour chaque jour de la semaine, puis additionnées pour obtenir le total de la semaine.';
        break;
      case 'monthly':
        periodLabel = 'Mois sélectionné';
        explanation = 'Cette valeur représente la somme totale des économies (balance) pour le mois sélectionné. Les économies sont calculées comme la différence entre les revenus et les dépenses pour chaque jour du mois, puis additionnées pour obtenir le total du mois.';
        break;
      case '3months':
        periodLabel = '3 derniers mois';
        explanation = 'Cette valeur représente la somme totale des économies (balance) sur les 3 derniers mois. Les économies sont calculées comme la différence entre les revenus et les dépenses pour chaque mois, puis additionnées pour obtenir le total sur les 3 mois.';
        break;
      case '6months':
        periodLabel = '6 derniers mois';
        explanation = 'Cette valeur représente la somme totale des économies (balance) sur les 6 derniers mois. Les économies sont calculées comme la différence entre les revenus et les dépenses pour chaque mois, puis additionnées pour obtenir le total sur les 6 mois.';
        break;
      default:
        periodLabel = 'Période sélectionnée';
        explanation = 'Cette valeur représente la somme totale des économies (balance) sur la période sélectionnée. Les économies sont calculées comme la différence entre les revenus et les dépenses.';
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
              StatisticsCardType.savingsCard.icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                StatisticsCardType.savingsCard.title,
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
                explanation,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Période analysée
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Période analysée :',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      periodLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Valeur actuelle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Valeur actuelle',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      formatter.format(savings),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
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
                color: AppTheme.primaryColor,
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

/// Widget pour la carte Moyenne Dépenses
class AverageExpenseCardWidget extends StatelessWidget {
  final double averageExpense;
  final String period; // "daily", "weekly", "monthly", "3months", "6months"
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
        ],
      ),
    );
  }

  void _showAverageExpenseInfoDialog(BuildContext context, double averageExpense, String period, int numberOfPeriods, DateTime selectedDate) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    String periodLabel = 'Période sélectionnée'; // Valeur par défaut
    String calculationExplanation = '';
    
    switch (period) {
      case 'daily':
        periodLabel = 'Période sélectionnée : ${DateFormat('d MMMM yyyy', 'fr').format(selectedDate)}'; // Ex: "Période sélectionnée : 25 décembre 2025"
        calculationExplanation = 'Cette valeur représente le total des dépenses pour le jour sélectionné. Comme il s\'agit d\'un seul jour, la "moyenne" correspond au total des dépenses de cette journée.';
        break;
      case 'weekly':
        final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        String weekRange;
        if (startOfWeek.month == endOfWeek.month && startOfWeek.year == endOfWeek.year) {
          weekRange = '${startOfWeek.day}-${endOfWeek.day} ${DateFormat('MMMM yyyy', 'fr').format(startOfWeek)}'; // Ex: "22-28 décembre 2025"
        } else {
          weekRange = '${DateFormat('d MMM', 'fr').format(startOfWeek)} - ${DateFormat('d MMM yyyy', 'fr').format(endOfWeek)}'; // Ex: "29 déc. - 4 janv. 2026"
        }
        periodLabel = 'Période sélectionnée : $weekRange';
        calculationExplanation = 'La moyenne est calculée en divisant le total des dépenses de la semaine par le nombre réel de jours dans la semaine (7 jours). Cette moyenne représente vos dépenses quotidiennes moyennes sur la semaine.';
        break;
      case 'monthly':
        periodLabel = 'Période sélectionnée : ${DateFormat('MMMM yyyy', 'fr').format(selectedDate)}'; // Ex: "Période sélectionnée : décembre 2025"
        calculationExplanation = 'La moyenne est calculée en divisant le total des dépenses du mois par le nombre réel de jours dans le mois (28 à 31 jours selon le mois). Cette moyenne représente vos dépenses quotidiennes moyennes sur le mois.';
        break;
      case '3months':
        final endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final startDate = DateTime(selectedDate.year, selectedDate.month - 2, 1);
        periodLabel = 'Période sélectionnée : ${DateFormat('MMMM', 'fr').format(startDate)} - ${DateFormat('MMMM yyyy', 'fr').format(endDate)}'; // Ex: "Période sélectionnée : octobre - décembre 2025"
        calculationExplanation = 'La moyenne est calculée en divisant le total des dépenses des 3 derniers mois par le nombre réel de mois dans la période (3 mois). Cette moyenne représente vos dépenses mensuelles moyennes sur les 3 derniers mois.';
        break;
      case '6months':
        final endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final startDate = DateTime(selectedDate.year, selectedDate.month - 5, 1);
        periodLabel = 'Période sélectionnée : ${DateFormat('MMMM', 'fr').format(startDate)} - ${DateFormat('MMMM yyyy', 'fr').format(endDate)}'; // Ex: "Période sélectionnée : juillet - décembre 2025"
        calculationExplanation = 'La moyenne est calculée en divisant le total des dépenses des 6 derniers mois par le nombre réel de mois dans la période (6 mois). Cette moyenne représente vos dépenses mensuelles moyennes sur les 6 derniers mois.';
        break;
      default:
        periodLabel = 'Période sélectionnée';
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
                periodLabel,
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

/// Widget pour la carte Top Dépenses
class TopExpenseCardWidget extends StatefulWidget {
  final List<Expense> expenses; // Liste des dépenses filtrées
  final int initialCount; // Nombre initial de dépenses à afficher
  final String period; // Période sélectionnée pour détecter les changements

  const TopExpenseCardWidget({
    super.key,
    required this.expenses,
    this.initialCount = 2,
    required this.period,
  });

  @override
  State<TopExpenseCardWidget> createState() => _TopExpenseCardWidgetState();
}

class _TopExpenseCardWidgetState extends State<TopExpenseCardWidget> {
  late int _displayCount;
  late String _previousPeriod;

  @override
  void initState() {
    super.initState();
    _displayCount = widget.initialCount;
    _previousPeriod = widget.period;
  }

  @override
  void didUpdateWidget(TopExpenseCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la période a changé, réinitialiser le compteur à la valeur initiale
    if (oldWidget.period != widget.period) {
      _displayCount = widget.initialCount;
      _previousPeriod = widget.period;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy', 'fr');

    // Trier les dépenses par montant décroissant et prendre les N premières
    final sortedExpenses = List<Expense>.from(widget.expenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topExpenses = sortedExpenses.take(_displayCount).toList();

    return _BaseCardWidget(
      title: StatisticsCardType.topExpenseCard.title,
      icon: StatisticsCardType.topExpenseCard.icon,
      color: AppTheme.expenseColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur pour choisir le nombre de dépenses à afficher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nombre de dépenses:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: AppTheme.expenseColor,
                    onPressed: _displayCount > 2
                        ? () {
                            setState(() {
                              _displayCount--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    '$_displayCount',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.expenseColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: AppTheme.expenseColor,
                    onPressed: _displayCount < widget.expenses.length
                        ? () {
                            setState(() {
                              _displayCount++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Afficher les dépenses deux par ligne
          ...List.generate(
            (topExpenses.length / 2).ceil(),
            (rowIndex) {
              final startIndex = rowIndex * 2;
              final endIndex = (startIndex + 2).clamp(0, topExpenses.length);
              final rowExpenses = topExpenses.sublist(startIndex, endIndex);

              return Padding(
                padding: EdgeInsets.only(bottom: rowIndex < (topExpenses.length / 2).ceil() - 1 ? 12 : 0),
                child: Row(
                  children: [
                    ...rowExpenses.map((expense) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: rowExpenses.indexOf(expense) == 0 && rowExpenses.length == 2 ? 8 : 0,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.expenseColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.expenseColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Montant
                              Text(
                                formatter.format(expense.amount),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.expenseColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Catégorie
                              if (expense.category != null) ...[
                                Row(
                                  children: [
                                    if (expense.category!.icon != null) ...[
                                      Text(
                                        expense.category!.icon!,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        expense.category!.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                              // Date
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateFormatter.format(expense.date),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Espace vide si une seule dépense sur la ligne
                    if (rowExpenses.length == 1)
                      const Expanded(child: SizedBox()),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Widget pour la carte Moyenne Revenus
class AverageIncomeCardWidget extends StatelessWidget {
  final double averageIncome;
  final String period; // "daily", "weekly", "monthly", "3months", "6months"
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
        ],
      ),
    );
  }

  void _showAverageIncomeInfoDialog(BuildContext context, double averageIncome, String period, int numberOfPeriods, DateTime selectedDate) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    String periodLabel = 'Période sélectionnée'; // Valeur par défaut
    String calculationExplanation = '';
    
    switch (period) {
      case 'daily':
        periodLabel = 'Période sélectionnée : ${DateFormat('d MMMM yyyy', 'fr').format(selectedDate)}'; // Ex: "Période sélectionnée : 25 décembre 2025"
        calculationExplanation = 'Cette valeur représente le total des revenus pour le jour sélectionné. Comme il s\'agit d\'un seul jour, la "moyenne" correspond au total des revenus de cette journée.';
        break;
      case 'weekly':
        final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        String weekRange;
        if (startOfWeek.month == endOfWeek.month && startOfWeek.year == endOfWeek.year) {
          weekRange = '${startOfWeek.day}-${endOfWeek.day} ${DateFormat('MMMM yyyy', 'fr').format(startOfWeek)}'; // Ex: "22-28 décembre 2025"
        } else {
          weekRange = '${DateFormat('d MMM', 'fr').format(startOfWeek)} - ${DateFormat('d MMM yyyy', 'fr').format(endOfWeek)}'; // Ex: "29 déc. - 4 janv. 2026"
        }
        periodLabel = 'Période sélectionnée : $weekRange';
        calculationExplanation = 'La moyenne est calculée en divisant le total des revenus de la semaine par le nombre réel de jours dans la semaine (7 jours). Cette moyenne représente vos revenus quotidiens moyens sur la semaine.';
        break;
      case 'monthly':
        periodLabel = 'Période sélectionnée : ${DateFormat('MMMM yyyy', 'fr').format(selectedDate)}'; // Ex: "Période sélectionnée : décembre 2025"
        calculationExplanation = 'La moyenne est calculée en divisant le total des revenus du mois par le nombre réel de jours dans le mois (28 à 31 jours selon le mois). Cette moyenne représente vos revenus quotidiens moyens sur le mois.';
        break;
      case '3months':
        final endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final startDate = DateTime(selectedDate.year, selectedDate.month - 2, 1);
        periodLabel = 'Période sélectionnée : ${DateFormat('MMMM', 'fr').format(startDate)} - ${DateFormat('MMMM yyyy', 'fr').format(endDate)}'; // Ex: "Période sélectionnée : octobre - décembre 2025"
        calculationExplanation = 'La moyenne est calculée en divisant le total des revenus des 3 derniers mois par le nombre réel de mois dans la période (3 mois). Cette moyenne représente vos revenus mensuels moyens sur les 3 derniers mois.';
        break;
      case '6months':
        final endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final startDate = DateTime(selectedDate.year, selectedDate.month - 5, 1);
        periodLabel = 'Période sélectionnée : ${DateFormat('MMMM', 'fr').format(startDate)} - ${DateFormat('MMMM yyyy', 'fr').format(endDate)}'; // Ex: "Période sélectionnée : juillet - décembre 2025"
        calculationExplanation = 'La moyenne est calculée en divisant le total des revenus des 6 derniers mois par le nombre réel de mois dans la période (6 mois). Cette moyenne représente vos revenus mensuels moyens sur les 6 derniers mois.';
        break;
      default:
        periodLabel = 'Période sélectionnée';
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
                periodLabel,
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

/// Widget pour la carte Top Catégories (5 catégories, deux par ligne)
class TopCategoriesCardWidget extends StatelessWidget {
  final List<dynamic> categories; // List<CategoryExpense>

  const TopCategoriesCardWidget({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'MAD ', decimalDigits: 0);
    
    return _BaseCardWidget(
      title: StatisticsCardType.topCategoryCard.title,
      icon: StatisticsCardType.topCategoryCard.icon,
      color: AppTheme.expenseColor, // Étoile en rouge (dépenses)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Afficher les catégories deux par ligne
          ...List.generate(
            (categories.length / 2).ceil(),
            (rowIndex) {
              final startIndex = rowIndex * 2;
              final endIndex = (startIndex + 2).clamp(0, categories.length);
              final rowCategories = categories.sublist(startIndex, endIndex);
              
              return Padding(
                padding: EdgeInsets.only(bottom: rowIndex < (categories.length / 2).ceil() - 1 ? 12 : 0),
                child: Row(
                  children: rowCategories.map((category) {
                    final categoryExpense = category as dynamic;
                    Color categoryColor;
                    try {
                      categoryColor = Color(int.parse(categoryExpense.categoryColor.replaceFirst('#', '0xFF')));
                    } catch (e) {
                      categoryColor = AppTheme.primaryColor;
                    }
                    
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: rowCategories.indexOf(category) == 0 ? 8 : 0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: categoryColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    categoryExpense.categoryIcon ?? '📦',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      categoryExpense.categoryName ?? 'Inconnu',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatter.format(categoryExpense.totalAmount ?? 0),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList()..addAll(
                    // Ajouter un Expanded vide si nombre impair de catégories
                    rowCategories.length == 1 ? [const Expanded(child: SizedBox.shrink())] : []
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Widget pour la carte Paiements Planifiés
class ScheduledPaymentsCardWidget extends StatelessWidget {
  final int upcomingCount;
  final double upcomingAmount;
  final int overdueCount;
  final double overdueAmount;

  const ScheduledPaymentsCardWidget({
    super.key,
    required this.upcomingCount,
    required this.upcomingAmount,
    required this.overdueCount,
    required this.overdueAmount,
  });

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
                StatisticsCardType.scheduledPaymentsCard.icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  StatisticsCardType.scheduledPaymentsCard.title,
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
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'À venir',
                  value: formatter.format(upcomingAmount),
                  count: upcomingCount,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: 'En retard',
                  value: formatter.format(overdueAmount),
                  count: overdueCount,
                  color: Colors.red,
                ),
              ),
            ],
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

/// Widget pour la carte Progression des Objectifs
class GoalsProgressCardWidget extends StatelessWidget {
  final List<dynamic> goals; // List<Goal>
  final double currentBalance;

  const GoalsProgressCardWidget({
    super.key,
    required this.goals,
    required this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return _BaseCardWidget(
        title: StatisticsCardType.goalsProgressCard.title,
        icon: StatisticsCardType.goalsProgressCard.icon,
        color: AppTheme.primaryColor,
        child: Center(
          child: Text(
            'Aucun objectif défini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    // Filtrer les objectifs non atteints et calculer le total
    final activeGoals = goals.where((g) => !(g.isAchieved ?? false)).toList();
    if (activeGoals.isEmpty) {
      return _BaseCardWidget(
        title: StatisticsCardType.goalsProgressCard.title,
        icon: StatisticsCardType.goalsProgressCard.icon,
        color: AppTheme.primaryColor,
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              Text(
                'Tous vos objectifs sont atteints !',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculer la progression globale
    double totalTarget = 0;
    double totalCurrent = 0;

    for (var goal in activeGoals) {
      final targetAmount = (goal.targetAmount as num).toDouble();
      final currentAmount = (goal.currentAmount as num?)?.toDouble() ?? 0.0;
      totalTarget += targetAmount;
      totalCurrent += currentAmount;
    }

    final overallProgress = totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0.0;
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
                StatisticsCardType.goalsProgressCard.icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  StatisticsCardType.goalsProgressCard.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Jauge de progression globale
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression globale',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${(overallProgress * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: overallProgress,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Économisé',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(totalCurrent),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Objectif',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(totalTarget),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
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
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$count paiement${count > 1 ? 's' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../models/income.dart';
import '../../theme/app_theme.dart';

class CalendarChartWidget extends StatelessWidget {
  final List<Expense> expenses;
  final List<Income> incomes;
  final DateTime selectedDate;
  final String period; // daily, weekly, monthly

  const CalendarChartWidget({
    super.key,
    required this.expenses,
    required this.incomes,
    required this.selectedDate,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer la plage de dates selon la période sélectionnée
    final dateRange = _calculateDateRange(period, selectedDate);
    final startDate = dateRange['startDate']!;
    final endDate = dateRange['endDate']!;
    
    // Normaliser les dates pour la comparaison (sans heures)
    final startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateNormalized = DateTime(endDate.year, endDate.month, endDate.day);
    
    // Créer une map pour accéder rapidement aux données par jour
    final Map<DateTime, double> dailyExpenses = {};
    final Map<DateTime, double> dailyIncomes = {};
    
    // Filtrer et remplir les maps avec les données selon la période
    for (var expense in expenses) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (expenseDate.compareTo(startDateNormalized) >= 0 && 
          expenseDate.compareTo(endDateNormalized) <= 0) {
        dailyExpenses[expenseDate] = (dailyExpenses[expenseDate] ?? 0.0) + expense.amount;
      }
    }
    
    for (var income in incomes) {
      final incomeDate = DateTime(income.date.year, income.date.month, income.date.day);
      if (incomeDate.compareTo(startDateNormalized) >= 0 && 
          incomeDate.compareTo(endDateNormalized) <= 0) {
        dailyIncomes[incomeDate] = (dailyIncomes[incomeDate] ?? 0.0) + income.amount;
      }
    }

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
          // Titre
          Text(
            'Revenus vs Dépenses',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // En-têtes des jours de la semaine
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
                .map((day) => SizedBox(
                      width: 45,
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          
          // Grille du calendrier selon la période
          period == 'weekly'
              ? _buildWeeklyGrid(startDate, dailyExpenses, dailyIncomes)
              : period == 'daily'
                  ? _buildDailyGrid(selectedDate, dailyExpenses, dailyIncomes)
                  : _buildMonthlyGrid(selectedDate, dailyExpenses, dailyIncomes),
          
          const SizedBox(height: 16),
          
          // Légende
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: AppTheme.incomeColor,
                label: 'Revenus',
              ),
              const SizedBox(width: 24),
              _LegendItem(
                color: AppTheme.expenseColor,
                label: 'Dépenses',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit la grille pour la période hebdomadaire (7 jours seulement)
  Widget _buildWeeklyGrid(
    DateTime startDate,
    Map<DateTime, double> dailyExpenses,
    Map<DateTime, double> dailyIncomes,
  ) {
    final List<Widget> weekRow = [];
    
    // Afficher les 7 jours de la semaine
    for (int i = 0; i < 7; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final expense = dailyExpenses[dateKey];
      final income = dailyIncomes[dateKey];
      
      weekRow.add(
        SizedBox(
          width: 45,
          height: 50,
          child: _CalendarDayCell(
            day: currentDate.day,
            expense: expense != null && expense > 0 ? expense : null,
            income: income != null && income > 0 ? income : null,
            isHighlighted: false,
          ),
        ),
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekRow,
    );
  }
  
  /// Construit la grille pour la période quotidienne (semaine complète avec jour sélectionné mis en évidence)
  Widget _buildDailyGrid(
    DateTime selectedDate,
    Map<DateTime, double> dailyExpenses,
    Map<DateTime, double> dailyIncomes,
  ) {
    // Trouver le début de la semaine (dimanche)
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final selectedDateKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    final List<Widget> weekRow = [];
    
    // Afficher les 7 jours de la semaine
    for (int i = 0; i < 7; i++) {
      final currentDate = startOfWeek.add(Duration(days: i));
      final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final expense = dailyExpenses[dateKey];
      final income = dailyIncomes[dateKey];
      final isSelected = dateKey.isAtSameMomentAs(selectedDateKey);
      
      weekRow.add(
        SizedBox(
          width: 45,
          height: 50,
          child: _CalendarDayCell(
            day: currentDate.day,
            expense: expense != null && expense > 0 ? expense : null,
            income: income != null && income > 0 ? income : null,
            isHighlighted: isSelected,
          ),
        ),
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekRow,
    );
  }
  
  /// Construit la grille pour les périodes mensuelles (calendrier complet du mois)
  Widget _buildMonthlyGrid(
    DateTime selectedDate,
    Map<DateTime, double> dailyExpenses,
    Map<DateTime, double> dailyIncomes,
  ) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Dimanche, 1 = Lundi, etc.
    
    final List<Widget> rows = [];
    int currentDay = 1;
    final totalDays = lastDayOfMonth.day;
    
    while (currentDay <= totalDays) {
      final List<Widget> weekRow = [];
      
      for (int weekday = 0; weekday < 7; weekday++) {
        if (currentDay == 1 && weekday < firstWeekday) {
          // Jours du mois précédent - case vide
          weekRow.add(const SizedBox(width: 45, height: 50));
        } else if (currentDay <= totalDays) {
          // Jour du mois actuel
          final day = currentDay;
          final dateKey = DateTime(selectedDate.year, selectedDate.month, day);
          final expense = dailyExpenses[dateKey];
          final income = dailyIncomes[dateKey];
          
          weekRow.add(
            SizedBox(
              width: 45,
              height: 50,
              child: _CalendarDayCell(
                day: day,
                expense: expense != null && expense > 0 ? expense : null,
                income: income != null && income > 0 ? income : null,
                isHighlighted: false,
              ),
            ),
          );
          currentDay++;
        } else {
          // Jours du mois suivant - case vide
          weekRow.add(const SizedBox(width: 45, height: 50));
        }
      }
      
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekRow,
        ),
      );
    }
    
    return Column(children: rows);
  }

  /// Calcule la plage de dates selon la période sélectionnée
  Map<String, DateTime> _calculateDateRange(String period, DateTime selectedDate) {
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'daily':
        startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
        break;
      
      case 'weekly':
        // Calculer le dimanche de la semaine (premier jour de la semaine)
        final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate = startDate.add(const Duration(days: 6));
        endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        break;
      
      case 'monthly':
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
        break;
      
      default:
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
    }

    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final double? expense;
  final double? income;
  final bool isHighlighted;

  const _CalendarDayCell({
    required this.day,
    this.expense,
    this.income,
    this.isHighlighted = false,
  });

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlighted ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isHighlighted ? 2 : 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Numéro du jour - taille réduite
          Text(
            day.toString(),
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          
          // Revenus (vert)
          if (income != null && income! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.incomeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _formatAmount(income!),
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.incomeColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          // Dépenses (rouge)
          if (expense != null && expense! > 0)
            Container(
              margin: EdgeInsets.only(top: income != null && income! > 0 ? 1 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.expenseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _formatAmount(expense!),
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.expenseColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}


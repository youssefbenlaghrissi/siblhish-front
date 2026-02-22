import 'package:flutter/material.dart';

/// Types de cartes statistiques (alignés sur la table cards en base : id 1-7).
enum StatisticsCardType {
  barChart, // id 1 - Graphique Revenus vs Dépenses
  pieChart, // id 2 - Répartition par Catégorie
  topBudgetCategoriesCard, // id 3 - Top Catégories Budgétisées
  budgetDistributionPieChart, // id 4 - Répartition des Budgets
  transactionCountCard, // id 5 - Nombre de Transactions
  averageExpenseCard, // id 6 - Moyenne Dépenses
  averageIncomeCard, // id 7 - Moyenne Revenus
}

extension StatisticsCardTypeExtension on StatisticsCardType {
  String get id {
    switch (this) {
      case StatisticsCardType.barChart:
        return 'bar_chart';
      case StatisticsCardType.pieChart:
        return 'pie_chart';
      case StatisticsCardType.topBudgetCategoriesCard:
        return 'top_budget_categories_card';
      case StatisticsCardType.budgetDistributionPieChart:
        return 'budget_distribution_pie_chart';
      case StatisticsCardType.transactionCountCard:
        return 'transaction_count_card';
      case StatisticsCardType.averageExpenseCard:
        return 'average_expense_card';
      case StatisticsCardType.averageIncomeCard:
        return 'average_income_card';
    }
  }

  String get title {
    switch (this) {
      case StatisticsCardType.barChart:
        return 'Graphique Revenus vs Dépenses';
      case StatisticsCardType.pieChart:
        return 'Répartition par Catégorie';
      case StatisticsCardType.topBudgetCategoriesCard:
        return 'Top Catégories Budgétisées';
      case StatisticsCardType.budgetDistributionPieChart:
        return 'Répartition des Budgets';
      case StatisticsCardType.transactionCountCard:
        return 'Nombre de Transactions';
      case StatisticsCardType.averageExpenseCard:
        return 'Moyenne Dépenses';
      case StatisticsCardType.averageIncomeCard:
        return 'Moyenne Revenus';
    }
  }

  String get description {
    switch (this) {
      case StatisticsCardType.barChart:
        return 'Comparaison des revenus et dépenses par mois';
      case StatisticsCardType.pieChart:
        return 'Visualisation de la répartition des dépenses par catégorie';
      case StatisticsCardType.topBudgetCategoriesCard:
        return 'Catégories avec les budgets les plus importants';
      case StatisticsCardType.budgetDistributionPieChart:
        return 'Répartition du budget total par catégorie';
      case StatisticsCardType.transactionCountCard:
        return 'Nombre total de transactions';
      case StatisticsCardType.averageExpenseCard:
        return 'Dépense moyenne selon la période sélectionnée';
      case StatisticsCardType.averageIncomeCard:
        return 'Revenu moyen selon la période sélectionnée';
    }
  }

  IconData get icon {
    switch (this) {
      case StatisticsCardType.barChart:
        return Icons.bar_chart_rounded;
      case StatisticsCardType.pieChart:
        return Icons.pie_chart_rounded;
      case StatisticsCardType.topBudgetCategoriesCard:
        return Icons.emoji_events_rounded;
      case StatisticsCardType.budgetDistributionPieChart:
        return Icons.pie_chart_outline_rounded;
      case StatisticsCardType.transactionCountCard:
        return Icons.receipt_long_rounded;
      case StatisticsCardType.averageExpenseCard:
        return Icons.trending_down_rounded;
      case StatisticsCardType.averageIncomeCard:
        return Icons.trending_up_rounded;
    }
  }

  /// Convertir un ID (numérique ou code) en StatisticsCardType
  static StatisticsCardType? fromId(String id) {
    for (var type in StatisticsCardType.values) {
      if (type.id == id) {
        return type;
      }
    }
    return null;
  }

  static List<StatisticsCardType> get allTypes => StatisticsCardType.values;
}

class StatisticsCard {
  final StatisticsCardType type;
  final bool isSelected;

  StatisticsCard({
    required this.type,
    this.isSelected = false,
  });
}

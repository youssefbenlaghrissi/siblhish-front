import 'package:flutter/material.dart';

enum StatisticsCardType {
  barChart, // Graphique en barres
  pieChart, // Graphique secteurs
  balanceCard, // Carte solde
  savingsCard, // Carte économies
  averageExpenseCard, // Carte moyenne dépenses
  topExpenseCard, // Carte dépense la plus élevée
  averageIncomeCard, // Carte moyenne revenus
  transactionCountCard, // Carte nombre transactions
  topCategoryCard, // Carte top catégorie
  scheduledPaymentsCard, // Carte paiements planifiés
  goalsProgressCard, // Carte progression des objectifs
  budgetVsActualChart, // Graphique Budget vs Réel
  topBudgetCategoriesCard, // Top catégories budgétisées
  budgetEfficiencyCard, // Efficacité budgétaire
  budgetDistributionPieChart, // Répartition budgets
}

extension StatisticsCardTypeExtension on StatisticsCardType {
  String get id {
    switch (this) {
      case StatisticsCardType.barChart:
        return 'bar_chart';
      case StatisticsCardType.pieChart:
        return 'pie_chart';
      case StatisticsCardType.balanceCard:
        return 'balance_card';
      case StatisticsCardType.savingsCard:
        return 'savings_card';
      case StatisticsCardType.averageExpenseCard:
        return 'average_expense_card';
      case StatisticsCardType.topExpenseCard:
        return 'top_expense_card';
      case StatisticsCardType.averageIncomeCard:
        return 'average_income_card';
      case StatisticsCardType.transactionCountCard:
        return 'transaction_count_card';
      case StatisticsCardType.topCategoryCard:
        return 'top_category_card';
      case StatisticsCardType.scheduledPaymentsCard:
        return 'scheduled_payments_card';
      case StatisticsCardType.goalsProgressCard:
        return 'goals_progress_card';
      case StatisticsCardType.budgetVsActualChart:
        return 'budget_vs_actual_chart';
      case StatisticsCardType.topBudgetCategoriesCard:
        return 'top_budget_categories_card';
      case StatisticsCardType.budgetEfficiencyCard:
        return 'budget_efficiency_card';
      case StatisticsCardType.budgetDistributionPieChart:
        return 'budget_distribution_pie_chart';
    }
  }

  String get title {
    switch (this) {
      case StatisticsCardType.barChart:
        return 'Graphique Revenus vs Dépenses';
      case StatisticsCardType.pieChart:
        return 'Répartition par Catégorie';
      case StatisticsCardType.balanceCard:
        return 'Solde Actuel';
      case StatisticsCardType.savingsCard:
        return 'Économies';
      case StatisticsCardType.averageExpenseCard:
        return 'Moyenne Dépenses';
      case StatisticsCardType.topExpenseCard:
        return 'Dépense la Plus Élevée';
      case StatisticsCardType.averageIncomeCard:
        return 'Moyenne Revenus';
      case StatisticsCardType.transactionCountCard:
        return 'Nombre de Transactions';
      case StatisticsCardType.topCategoryCard:
        return 'Top Catégorie';
      case StatisticsCardType.scheduledPaymentsCard:
        return 'Paiements Planifiés';
      case StatisticsCardType.goalsProgressCard:
        return 'Progression des Objectifs';
      case StatisticsCardType.budgetVsActualChart:
        return 'Budget vs Réel';
      case StatisticsCardType.topBudgetCategoriesCard:
        return 'Top Catégories Budgétisées';
      case StatisticsCardType.budgetEfficiencyCard:
        return 'Efficacité Budgétaire';
      case StatisticsCardType.budgetDistributionPieChart:
        return 'Répartition des Budgets';
    }
  }

  String get description {
    switch (this) {
      case StatisticsCardType.barChart:
        return 'Comparaison des revenus et dépenses par mois';
      case StatisticsCardType.pieChart:
        return 'Visualisation de la répartition des dépenses par catégorie';
      case StatisticsCardType.balanceCard:
        return 'Solde actuel de votre compte';
      case StatisticsCardType.savingsCard:
        return 'Économies selon la période sélectionnée';
      case StatisticsCardType.averageExpenseCard:
        return 'Dépense moyenne selon la période sélectionnée';
      case StatisticsCardType.topExpenseCard:
        return 'La dépense la plus importante';
      case StatisticsCardType.averageIncomeCard:
        return 'Revenu moyen selon la période sélectionnée';
      case StatisticsCardType.transactionCountCard:
        return 'Nombre total de transactions';
      case StatisticsCardType.topCategoryCard:
        return 'Catégorie avec le plus de dépenses';
      case StatisticsCardType.scheduledPaymentsCard:
        return 'Statistiques sur les paiements planifiés';
      case StatisticsCardType.goalsProgressCard:
        return 'Avancement vers vos objectifs financiers';
      case StatisticsCardType.budgetVsActualChart:
        return 'Comparaison entre budgets prévus et dépenses réelles';
      case StatisticsCardType.topBudgetCategoriesCard:
        return 'Catégories avec les budgets les plus importants';
      case StatisticsCardType.budgetEfficiencyCard:
        return 'Mesure de l\'efficacité de vos budgets';
      case StatisticsCardType.budgetDistributionPieChart:
        return 'Répartition du budget total par catégorie';
    }
  }

  IconData get icon {
    switch (this) {
      case StatisticsCardType.barChart:
        return Icons.bar_chart_rounded;
      case StatisticsCardType.pieChart:
        return Icons.pie_chart_rounded;
      case StatisticsCardType.balanceCard:
        return Icons.account_balance_wallet_rounded;
      case StatisticsCardType.savingsCard:
        return Icons.savings_rounded;
      case StatisticsCardType.averageExpenseCard:
        return Icons.trending_down_rounded;
      case StatisticsCardType.topExpenseCard:
        return Icons.arrow_upward_rounded;
      case StatisticsCardType.averageIncomeCard:
        return Icons.trending_up_rounded;
      case StatisticsCardType.transactionCountCard:
        return Icons.receipt_long_rounded;
      case StatisticsCardType.topCategoryCard:
        return Icons.star_rounded;
      case StatisticsCardType.scheduledPaymentsCard:
        return Icons.schedule_rounded;
      case StatisticsCardType.goalsProgressCard:
        return Icons.flag_rounded;
      case StatisticsCardType.budgetVsActualChart:
        return Icons.compare_arrows_rounded;
      case StatisticsCardType.topBudgetCategoriesCard:
        return Icons.emoji_events_rounded;
      case StatisticsCardType.budgetEfficiencyCard:
        return Icons.savings_rounded;
      case StatisticsCardType.budgetDistributionPieChart:
        return Icons.pie_chart_outline_rounded;
    }
  }

  /// Convertir un ID (numérique ou code) en StatisticsCardType
  /// Utilise uniquement le code directement (pas de mapping figé)
  /// Le code doit correspondre à un StatisticsCardType existant
  static StatisticsCardType? fromId(String id) {
    // Chercher directement le type correspondant au code/id
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


import 'budget_vs_actual.dart';
import 'budget_efficiency.dart';
import 'budget_distribution.dart';

/// Modèle unifié pour toutes les statistiques budgets
/// Contient toutes les données nécessaires pour les 4 graphiques budgets
class BudgetStatistics {
  final List<BudgetVsActual> budgetVsActual;
  final BudgetEfficiency efficiency;
  final List<BudgetDistribution> distribution;

  BudgetStatistics({
    required this.budgetVsActual,
    required this.efficiency,
    required this.distribution,
  });

  factory BudgetStatistics.fromJson(Map<String, dynamic> json) {
    return BudgetStatistics(
      budgetVsActual: (json['budgetVsActual'] as List<dynamic>?)
              ?.map((item) => BudgetVsActual.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      efficiency: BudgetEfficiency.fromJson(
        json['efficiency'] as Map<String, dynamic>? ?? {},
      ),
      distribution: (json['distribution'] as List<dynamic>?)
              ?.map((item) => BudgetDistribution.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budgetVsActual': budgetVsActual.map((item) => {
            'categoryId': item.categoryId,
            'categoryName': item.categoryName,
            'icon': item.icon,
            'color': item.color,
            'budgetAmount': item.budgetAmount,
            'actualAmount': item.actualAmount,
            'difference': item.difference,
            'percentageUsed': item.percentageUsed,
          }).toList(),
      'efficiency': {
        'totalBudgetAmount': efficiency.totalBudgetAmount,
        'totalSpentAmount': efficiency.totalSpentAmount,
        'totalRemainingAmount': efficiency.totalRemainingAmount,
        'averagePercentageUsed': efficiency.averagePercentageUsed,
        'totalBudgets': efficiency.totalBudgets,
        'budgetsOnTrack': efficiency.budgetsOnTrack,
        'budgetsExceeded': efficiency.budgetsExceeded,
      },
      'distribution': distribution.map((item) => {
            'categoryId': item.categoryId,
            'categoryName': item.categoryName,
            'icon': item.icon,
            'color': item.color,
            'budgetAmount': item.budgetAmount,
            'percentage': item.percentage,
          }).toList(),
    };
  }
}


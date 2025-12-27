class BudgetEfficiency {
  final double totalBudgetAmount;
  final double totalSpentAmount;
  final double totalRemainingAmount;
  final double averagePercentageUsed;
  final int totalBudgets;
  final int budgetsOnTrack;
  final int budgetsExceeded;

  BudgetEfficiency({
    required this.totalBudgetAmount,
    required this.totalSpentAmount,
    required this.totalRemainingAmount,
    required this.averagePercentageUsed,
    required this.totalBudgets,
    required this.budgetsOnTrack,
    required this.budgetsExceeded,
  });

  factory BudgetEfficiency.fromJson(Map<String, dynamic> json) {
    return BudgetEfficiency(
      totalBudgetAmount: (json['totalBudgetAmount'] as num?)?.toDouble() ?? 0.0,
      totalSpentAmount: (json['totalSpentAmount'] as num?)?.toDouble() ?? 0.0,
      totalRemainingAmount: (json['totalRemainingAmount'] as num?)?.toDouble() ?? 0.0,
      averagePercentageUsed: (json['averagePercentageUsed'] as num?)?.toDouble() ?? 0.0,
      totalBudgets: json['totalBudgets'] ?? 0,
      budgetsOnTrack: json['budgetsOnTrack'] ?? 0,
      budgetsExceeded: json['budgetsExceeded'] ?? 0,
    );
  }
}


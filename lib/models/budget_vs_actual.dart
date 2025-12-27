class BudgetVsActual {
  final int? categoryId;
  final String categoryName;
  final String icon;
  final String color;
  final double budgetAmount;
  final double actualAmount;
  final double difference;
  final double percentageUsed;

  BudgetVsActual({
    this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.budgetAmount,
    required this.actualAmount,
    required this.difference,
    required this.percentageUsed,
  });

  factory BudgetVsActual.fromJson(Map<String, dynamic> json) {
    return BudgetVsActual(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? 'Budget Global',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#9E9E9E',
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      actualAmount: (json['actualAmount'] as num).toDouble(),
      difference: (json['difference'] as num).toDouble(),
      percentageUsed: (json['percentageUsed'] as num).toDouble(),
    );
  }
}


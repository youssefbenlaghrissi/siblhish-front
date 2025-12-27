class BudgetDistribution {
  final int? categoryId;
  final String categoryName;
  final String icon;
  final String color;
  final double budgetAmount;
  final double percentage;

  BudgetDistribution({
    this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.budgetAmount,
    required this.percentage,
  });

  factory BudgetDistribution.fromJson(Map<String, dynamic> json) {
    return BudgetDistribution(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? 'Budget Global',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#9E9E9E',
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}


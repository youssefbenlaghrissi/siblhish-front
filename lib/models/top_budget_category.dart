class TopBudgetCategory {
  final int? categoryId;
  final String categoryName;
  final String icon;
  final String color;
  final double budgetAmount;
  final double spentAmount;
  final double remainingAmount;
  final double percentageUsed;

  TopBudgetCategory({
    this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.budgetAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
  });

  factory TopBudgetCategory.fromJson(Map<String, dynamic> json) {
    return TopBudgetCategory(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? 'Budget Global',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#9E9E9E',
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      percentageUsed: (json['percentageUsed'] as num).toDouble(),
    );
  }
}


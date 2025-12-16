// Modèle Budget adapté au backend Spring Boot
class Budget {
  final String id;
  final double amount;
  final String period; // DAILY, WEEKLY, MONTHLY, YEARLY
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? categoryId; // null for global budget
  final String userId;

  Budget({
    required this.id,
    required this.amount,
    required this.period,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.categoryId,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'period': period,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': isActive,
        'categoryId': categoryId,
        'userId': userId,
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'].toString(),
        amount: json['amount'].toDouble(),
        period: json['period'],
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        isActive: json['isActive'] ?? true,
        categoryId: json['categoryId']?.toString(),
        userId: json['userId'].toString(),
      );
}

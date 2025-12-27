// Modèle Budget adapté au backend Spring Boot
class Budget {
  final String id;
  final double amount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId; // null for global budget
  final String userId;
  final bool isRecurring; // Budget récurrent (créé automatiquement chaque mois, calculé par le backend)
  final double spent; // Montant dépensé (calculé par le backend)
  final double percentageUsed; // Pourcentage utilisé (calculé par le backend)

  Budget({
    required this.id,
    required this.amount,
    this.startDate,
    this.endDate,
    this.categoryId,
    required this.userId,
    this.isRecurring = false,
    this.spent = 0.0,
    this.percentageUsed = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'categoryId': categoryId,
        'userId': userId,
        'isRecurring': isRecurring,
        'spent': spent,
        'percentageUsed': percentageUsed,
      };

  factory Budget.fromJson(Map<String, dynamic> json) {
    // Extraire categoryId depuis category.id si categoryId n'existe pas directement
    final categoryId = json['categoryId']?.toString() ?? json['category']?['id']?.toString();
    
    return Budget(
      id: json['id'].toString(),
      amount: json['amount'].toDouble(),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      categoryId: categoryId,
      userId: json['userId'].toString(),
      isRecurring: json['isRecurring'] ?? false,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      percentageUsed: (json['percentageUsed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

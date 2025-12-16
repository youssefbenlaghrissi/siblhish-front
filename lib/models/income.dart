// Modèle Income adapté au backend Spring Boot
class Income {
  final String id;
  final double amount;
  final String paymentMethod; // CASH, CREDIT_CARD, etc.
  final DateTime date;
  final String? description;
  final String? source; // Salaire, Freelance, etc.
  final bool isRecurring;
  final String? recurrenceFrequency; // DAILY, WEEKLY, MONTHLY, YEARLY
  final String userId;

  Income({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    this.description,
    this.source,
    this.isRecurring = false,
    this.recurrenceFrequency,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'method': paymentMethod, // Backend attend 'method' dans IncomeRequestDto
        'date': date.toIso8601String(),
        'description': description,
        'source': source,
        'isRecurring': isRecurring,
        'recurrenceFrequency': recurrenceFrequency,
        'userId': int.tryParse(userId) ?? userId,
      };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'].toString(),
        amount: (json['amount'] as num).toDouble(),
        paymentMethod: json['method'] ?? json['paymentMethod'] ?? 'CASH',
        date: DateTime.parse(json['date']),
        description: json['description'],
        source: json['source'],
        isRecurring: json['isRecurring'] ?? false,
        recurrenceFrequency: json['recurrenceFrequency'],
        userId: json['userId'].toString(),
      );
}

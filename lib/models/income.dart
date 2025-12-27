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
  final DateTime? recurrenceEndDate; // Date limite pour "jusqu'à une certaine date"
  final List<int>? recurrenceDaysOfWeek; // Pour hebdomadaire: [1=Monday, 2=Tuesday, ...]
  final int? recurrenceDayOfMonth; // Pour mensuel: jour du mois (1-31)
  final int? recurrenceDayOfYear; // Pour annuel: jour de l'année (1-365)
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
    this.recurrenceEndDate,
    this.recurrenceDaysOfWeek,
    this.recurrenceDayOfMonth,
    this.recurrenceDayOfYear,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'method': paymentMethod,
        'date': date.toIso8601String().split('.')[0], // Format: 2024-12-17T10:30:00
        'description': description,
        'source': source,
        'isRecurring': isRecurring,
        'recurrenceFrequency': recurrenceFrequency,
        'recurrenceEndDate': recurrenceEndDate?.toIso8601String().split('.')[0],
        'recurrenceDaysOfWeek': recurrenceDaysOfWeek,
        'recurrenceDayOfMonth': recurrenceDayOfMonth,
        'recurrenceDayOfYear': recurrenceDayOfYear,
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
        recurrenceEndDate: json['recurrenceEndDate'] != null 
            ? DateTime.parse(json['recurrenceEndDate'])
            : null,
        recurrenceDaysOfWeek: json['recurrenceDaysOfWeek'] != null
            ? List<int>.from(json['recurrenceDaysOfWeek'])
            : null,
        recurrenceDayOfMonth: json['recurrenceDayOfMonth'],
        recurrenceDayOfYear: json['recurrenceDayOfYear'],
        userId: json['userId'].toString(),
      );
}

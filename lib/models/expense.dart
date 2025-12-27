// Modèle Expense adapté au backend Spring Boot (ExpenseDto)
import 'category.dart';

class Expense {
  final String id;
  final double amount;
  final String paymentMethod; // CASH, CREDIT_CARD, BANK_TRANSFER, MOBILE_PAYMENT, PAYPAL
  final DateTime date;
  final String? description;
  final String? location;
  final bool isRecurring;
  final String? recurrenceFrequency; // DAILY, WEEKLY, MONTHLY, YEARLY
  final DateTime? recurrenceEndDate; // Date limite pour "jusqu'à une certaine date"
  final List<int>? recurrenceDaysOfWeek; // Pour hebdomadaire: [1=Monday, 2=Tuesday, ...]
  final int? recurrenceDayOfMonth; // Pour mensuel: jour du mois (1-31)
  final int? recurrenceDayOfYear; // Pour annuel: jour de l'année (1-365)
  final String userId;
  final String? categoryId; // Peut être null si category est fourni
  final Category? category; // CategoryDto imbriqué depuis le backend

  Expense({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    this.description,
    this.location,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurrenceEndDate,
    this.recurrenceDaysOfWeek,
    this.recurrenceDayOfMonth,
    this.recurrenceDayOfYear,
    required this.userId,
    this.categoryId,
    this.category,
  });

  // Getter pour obtenir categoryId depuis category si disponible
  String get effectiveCategoryId => categoryId ?? category?.id ?? '';

  Map<String, dynamic> toJson() {
    final effectiveCatId = effectiveCategoryId;
    return {
      'amount': amount,
      'method': paymentMethod,
      'date': date.toIso8601String().split('.')[0], // Format: 2024-12-17T10:30:00
      'description': description,
      'location': location,
      'isRecurring': isRecurring,
      'recurrenceFrequency': recurrenceFrequency,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String().split('.')[0],
      'recurrenceDaysOfWeek': recurrenceDaysOfWeek,
      'recurrenceDayOfMonth': recurrenceDayOfMonth,
      'recurrenceDayOfYear': recurrenceDayOfYear,
      'userId': int.tryParse(userId) ?? userId,
      'categoryId': effectiveCatId.isNotEmpty 
          ? (int.tryParse(effectiveCatId) ?? effectiveCatId)
          : null,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    // Gérer les deux formats : avec category imbriqué ou categoryId seul
    Category? categoryObj;
    String? catId;
    
    if (json['category'] != null) {
      categoryObj = Category.fromJson(json['category'] as Map<String, dynamic>);
      catId = categoryObj.id;
    } else if (json['categoryId'] != null) {
      catId = json['categoryId'].toString();
    }

    return Expense(
      id: json['id'].toString(),
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['method'] ?? json['paymentMethod'] ?? 'CASH',
      date: DateTime.parse(json['date']),
      description: json['description'],
      location: json['location'],
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
      categoryId: catId,
      category: categoryObj,
    );
  }
}

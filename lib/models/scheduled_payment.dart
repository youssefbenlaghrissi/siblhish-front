class ScheduledPayment {
  final String id;
  final String name;
  final String categoryId;
  final String paymentMethod;
  final double amount;
  final String? beneficiary;
  final DateTime dueDate;
  final bool isRecurring;
  final String? recurrenceFrequency; // DAILY, WEEKLY, MONTHLY, YEARLY
  final DateTime? recurrenceEndDate;
  final List<int>? recurrenceDaysOfWeek; // 1=Monday .. 7=Sunday
  final int? recurrenceDayOfMonth;
  final int? recurrenceDayOfYear;
  final String notificationOption; // NONE, ON_DUE_DATE, ONE_DAY_BEFORE, THREE_DAYS_BEFORE
  final String userId;
  final bool isPaid;
  final DateTime? paidDate; // Date de paiement

  ScheduledPayment({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.paymentMethod,
    required this.amount,
    this.beneficiary,
    required this.dueDate,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurrenceEndDate,
    this.recurrenceDaysOfWeek,
    this.recurrenceDayOfMonth,
    this.recurrenceDayOfYear,
    this.notificationOption = 'NONE',
    required this.userId,
    this.isPaid = false,
    this.paidDate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'categoryId': int.tryParse(categoryId) ?? categoryId,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'beneficiary': beneficiary,
        'dueDate': dueDate.toIso8601String().split('.')[0],
        'isRecurring': isRecurring,
        'recurrenceFrequency': recurrenceFrequency,
        'recurrenceEndDate': recurrenceEndDate?.toIso8601String().split('.')[0],
        'recurrenceDaysOfWeek': recurrenceDaysOfWeek,
        'recurrenceDayOfMonth': recurrenceDayOfMonth,
        'recurrenceDayOfYear': recurrenceDayOfYear,
        'notificationOption': notificationOption,
        'userId': int.tryParse(userId) ?? userId,
        'isPaid': isPaid,
      };

  factory ScheduledPayment.fromJson(Map<String, dynamic> json) {
    DateTime? paidDate;
    if (json['paidDate'] != null) {
      try {
        paidDate = DateTime.parse(json['paidDate']);
      } catch (e) {
        paidDate = null;
      }
    }
    
    DateTime? recurrenceEndDate;
    if (json['recurrenceEndDate'] != null) {
      try {
        recurrenceEndDate = DateTime.parse(json['recurrenceEndDate']);
      } catch (_) {
        recurrenceEndDate = null;
      }
    }
    List<int>? recurrenceDaysOfWeek;
    if (json['recurrenceDaysOfWeek'] != null) {
      recurrenceDaysOfWeek = List<int>.from(json['recurrenceDaysOfWeek'] as List);
    }

    return ScheduledPayment(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      categoryId: (json['categoryId'] ?? json['category']?['id'])?.toString() ?? '',
      paymentMethod: json['paymentMethod'] ?? 'CASH',
      amount: (json['amount'] as num).toDouble(),
      beneficiary: json['beneficiary'],
      dueDate: DateTime.parse(json['dueDate']),
      isRecurring: json['isRecurring'] ?? false,
      recurrenceFrequency: json['recurrenceFrequency'],
      recurrenceEndDate: recurrenceEndDate,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek,
      recurrenceDayOfMonth: json['recurrenceDayOfMonth'],
      recurrenceDayOfYear: json['recurrenceDayOfYear'],
      notificationOption: json['notificationOption'] ?? 'NONE',
      userId: json['userId'].toString(),
      isPaid: json['isPaid'] ?? false,
      paidDate: paidDate,
    );
  }

  ScheduledPayment copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? paymentMethod,
    double? amount,
    String? beneficiary,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurrenceFrequency,
    DateTime? recurrenceEndDate,
    List<int>? recurrenceDaysOfWeek,
    int? recurrenceDayOfMonth,
    int? recurrenceDayOfYear,
    String? notificationOption,
    String? userId,
    bool? isPaid,
    DateTime? paidDate,
  }) {
    return ScheduledPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      beneficiary: beneficiary ?? this.beneficiary,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek ?? this.recurrenceDaysOfWeek,
      recurrenceDayOfMonth: recurrenceDayOfMonth ?? this.recurrenceDayOfMonth,
      recurrenceDayOfYear: recurrenceDayOfYear ?? this.recurrenceDayOfYear,
      notificationOption: notificationOption ?? this.notificationOption,
      userId: userId ?? this.userId,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
    );
  }
}


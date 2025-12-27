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
  final String notificationOption; // NONE, ON_DUE_DATE, ONE_DAY_BEFORE, THREE_DAYS_BEFORE
  final String userId;
  final bool isPaid;

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
    this.notificationOption = 'NONE',
    required this.userId,
    this.isPaid = false,
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
        'notificationOption': notificationOption,
        'userId': int.tryParse(userId) ?? userId,
        'isPaid': isPaid,
      };

  factory ScheduledPayment.fromJson(Map<String, dynamic> json) => ScheduledPayment(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        categoryId: (json['categoryId'] ?? json['category']?['id'])?.toString() ?? '',
        paymentMethod: json['paymentMethod'] ?? 'CASH',
        amount: (json['amount'] as num).toDouble(),
        beneficiary: json['beneficiary'],
        dueDate: DateTime.parse(json['dueDate']),
        isRecurring: json['isRecurring'] ?? false,
        recurrenceFrequency: json['recurrenceFrequency'],
        notificationOption: json['notificationOption'] ?? 'NONE',
        userId: json['userId'].toString(),
        isPaid: json['isPaid'] ?? false,
      );

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
    String? notificationOption,
    String? userId,
    bool? isPaid,
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
      notificationOption: notificationOption ?? this.notificationOption,
      userId: userId ?? this.userId,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}


// Modèle Notification adapté au backend Spring Boot
class Notification {
  final String id;
  final String title;
  final String description;
  final bool isRead;
  final String type; // DAILY_REPORT, MONTHLY_REPORT, RECURRING_TRANSACTION
  final String? transactionType; // INCOME, EXPENSE, null (pour autres types)
  final DateTime creationDate;

  Notification({
    required this.id,
    required this.title,
    required this.description,
    required this.isRead,
    required this.type,
    this.transactionType,
    required this.creationDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isRead': isRead,
        'type': type,
        'transactionType': transactionType,
        'creationDate': creationDate.toIso8601String(),
      };

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        isRead: json['isRead'] ?? false,
        type: json['type'] ?? 'RECURRING_TRANSACTION',
        transactionType: json['transactionType'] as String?,
        creationDate: DateTime.parse(json['creationDate']),
      );
}


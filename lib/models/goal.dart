// Modèle Goal adapté au backend Spring Boot
class Goal {
  final String id;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String userId;
  final String? categoryId;
  final bool isAchieved;

  Goal({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    required this.userId,
    this.categoryId,
    this.isAchieved = false,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate?.toIso8601String(),
        'userId': userId,
        'categoryId': categoryId,
        'isAchieved': isAchieved,
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    // Gérer category imbriqué depuis GoalDto
    String? catId;
    if (json['category'] != null) {
      final category = json['category'] as Map<String, dynamic>;
      catId = category['id'].toString();
    } else if (json['categoryId'] != null) {
      catId = json['categoryId'].toString();
    }

    return Goal(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      userId: json['userId'].toString(),
      categoryId: catId,
      isAchieved: json['isAchieved'] ?? false,
    );
  }
}

// Modèle Category adapté au backend Spring Boot
class Category {
  final String id;
  final String name;
  final String? icon;
  final String? color;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'].toString(),
        name: json['name'],
        icon: json['icon'],
        color: json['color'],
      );
}

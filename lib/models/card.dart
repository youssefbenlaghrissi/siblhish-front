class Card {
  final int id;
  final String code;
  final String title;

  Card({
    required this.id,
    required this.code,
    required this.title,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: json['id'] as int,
      code: json['code'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
    };
  }
}


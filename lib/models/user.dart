// Modèle User adapté au backend Spring Boot
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String language;
  final bool? notificationsEnabled;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.language = 'fr',
    this.notificationsEnabled = true,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'language': language,
        'notificationsEnabled': notificationsEnabled,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'].toString(),
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        password: json['password'] ?? '',
        language: json['language'] ?? 'fr',
        notificationsEnabled: json['notificationsEnabled'] ?? true,
      );
}

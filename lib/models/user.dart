// Modèle User adapté au backend Spring Boot
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String type; // EMPLOYEE, FREELANCER, etc.
  final String language;
  final double? monthlySalary;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.type,
    this.language = 'fr',
    this.monthlySalary,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'type': type,
        'language': language,
        'monthlySalary': monthlySalary,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'].toString(),
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        password: json['password'] ?? '', // Pas retourné dans UserProfileDto
        type: json['type'] ?? 'EMPLOYEE',
        language: json['language'] ?? 'fr',
        monthlySalary: (json['monthlySalary'] as num?)?.toDouble(),
      );
}

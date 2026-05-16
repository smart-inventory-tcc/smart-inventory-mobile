class User {
  final int id;
  final String username;
  final String role;
  final String? name;
  final String? email;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.name,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}

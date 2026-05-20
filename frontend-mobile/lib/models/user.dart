class User {
  final int id;
  final String username;
  final String role;
  final String? name;
  final String? email;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.name,
    this.email,
  });

  /// Mendukung tiga bentuk response dari Identity Service:
  /// 1. Login  : { data: { token, user: { id, username, role } } }
  /// 2. Profile: { data: { id, username, role, createdAt } }
  /// 3. Direct : { id, username, role }  ← untuk compat internal
  factory User.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map;
    if (json['data'] is Map) {
      final data = json['data'] as Map<String, dynamic>;
      // Login response bungkus user di dalam data.user
      map = data['user'] is Map
          ? data['user'] as Map<String, dynamic>
          : data;
    } else {
      map = json;
    }
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      role: map['role'] as String,
      name: map['name'] as String?,
      email: map['email'] as String?,
    );
  }
}

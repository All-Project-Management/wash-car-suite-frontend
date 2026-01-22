class AuthUser {
  final int id;
  final String role;
  final String fullName;
  final String email;

  const AuthUser({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
  });

  factory AuthUser.fromJHipsterAccountJson(Map<String, dynamic> j) {
    final id = (j['id'] as num?)?.toInt() ?? 0;
    final email = (j['email'] ?? '').toString();

    final firstName = (j['firstName'] ?? '').toString().trim();
    final lastName = (j['lastName'] ?? '').toString().trim();
    final login = (j['login'] ?? '').toString().trim();

    final computedFullName = [
      if (firstName.isNotEmpty) firstName,
      if (lastName.isNotEmpty) lastName,
    ].join(' ').trim();

    final fullName =
    computedFullName.isNotEmpty ? computedFullName : (login.isNotEmpty ? login : email);

    String role = '';
    final authorities = j['authorities'];
    if (authorities is List) {
      final list = authorities.map((e) => e.toString()).toList();
      if (list.isNotEmpty) role = list.first;
    }

    return AuthUser(
      id: id,
      role: role,
      fullName: fullName,
      email: email,
    );
  }
}

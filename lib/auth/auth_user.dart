class AuthUser {
  AuthUser({
    required this.login,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.authorities,
  });

  final String login;
  final String email;
  final String firstName;
  final String lastName;

  /// Comes from JHipster /api/account => "authorities": ["ROLE_USER","ROLE_ADMIN"]
  final List<String> authorities;

  String get fullName => ('${firstName.trim()} ${lastName.trim()}').trim();

  bool get isAdmin => authorities.contains('ROLE_ADMIN');
  bool get isUser => authorities.contains('ROLE_USER');

  /// Label used in UI
  String get roleLabel {
    if (isAdmin) return 'ADMIN';
    if (isUser) return 'USER';
    return 'GUEST';
  }

  factory AuthUser.fromJHipsterAccountJson(Map<String, dynamic> json) {
    final raw = json['authorities'];
    final auths = (raw is List) ? raw.map((e) => e.toString()).toList() : <String>[];

    return AuthUser(
      login: (json['login'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      authorities: auths,
    );
  }
}

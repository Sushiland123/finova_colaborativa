/// Entidad del dominio: Estado de autenticación
class AuthEntity {
  final bool isAuthenticated;
  final UserEntity? user;
  final String? accessToken;
  final String? refreshToken;

  const AuthEntity({
    required this.isAuthenticated,
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  AuthEntity copyWith({
    bool? isAuthenticated,
    UserEntity? user,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthEntity(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  /// Estado no autenticado
  static const AuthEntity unauthenticated = AuthEntity(
    isAuthenticated: false,
  );
}

/// Entidad simple para usuario en AuthEntity
class UserEntity {
  final String id;
  final String name;
  final String email;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
  });
}

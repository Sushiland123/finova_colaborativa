import '../entities/auth_entity.dart';

/// Interfaz del repositorio de autenticación
abstract class IAuthRepository {
  /// Iniciar sesión con email y contraseña
  Future<AuthEntity> login(String email, String password);

  /// Cerrar sesión
  Future<void> logout();

  /// Verificar si hay una sesión activa
  Future<bool> isLoggedIn();

  /// Obtener el usuario actual
  Future<UserEntity?> getCurrentUser();

  /// Refrescar el token de acceso
  Future<AuthEntity> refreshToken();

  /// Registrar nuevo usuario
  Future<AuthEntity> register({
    required String name,
    required String email,
    required String password,
  });
}

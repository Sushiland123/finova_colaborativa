import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../dtos/auth_dtos.dart';
import '../../core/errors/dio_error_mapper.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/logger.dart';

/// Implementación del repositorio de autenticación
class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource _remote;
  final DioClient _dioClient;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required DioClient dioClient,
  })  : _remote = remote,
        _dioClient = dioClient;

  @override
  Future<AuthEntity> login(String email, String password) async {
    try {
      final response = await _remote.login(
        LoginRequestDto(email: email, password: password),
      );

      if (response.tokens.accessToken.isEmpty || 
          response.tokens.refreshToken.isEmpty) {
        AppLogger.warning(
          '[AUTH_REPO] Tokens vacíos tras login. access="${response.tokens.accessToken}" refresh="${response.tokens.refreshToken}"',
        );
      }

      await _dioClient.saveToken(response.tokens.accessToken);
      await _dioClient.saveRefreshToken(response.tokens.refreshToken);

      // Mapear DTO a Entity
      return AuthEntity(
        isAuthenticated: true,
        user: response.user != null
            ? UserEntity(
                id: response.user!.id,
                name: response.user!.email.split('@').first, // Usar email como nombre temporal
                email: response.user!.email,
              )
            : null,
        accessToken: response.tokens.accessToken,
        refreshToken: response.tokens.refreshToken,
      );
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  @override
  Future<void> logout() async {
    AppLogger.info('[AUTH_REPO] Ejecutando logout...');
    try {
      await _remote.logout();
      AppLogger.info('[AUTH_REPO] Logout en backend exitoso');
    } catch (e) {
      AppLogger.warning('[AUTH_REPO] Error en logout backend: $e');
    } finally {
      // Asegurar limpieza local aunque el backend falle
      await _dioClient.clearTokens();
      AppLogger.info('[AUTH_REPO] Tokens limpiados localmente');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _dioClient.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // TODO: Implementar endpoint para obtener usuario actual
    // Por ahora retornamos null
    return null;
  }

  @override
  Future<AuthEntity> refreshToken() async {
    try {
      final refreshToken = await _dioClient.getToken(); // Obtener refresh token
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final tokens = await _remote.refresh(refreshToken);
      
      await _dioClient.saveToken(tokens.accessToken);
      await _dioClient.saveRefreshToken(tokens.refreshToken);

      return AuthEntity(
        isAuthenticated: true,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  @override
  Future<AuthEntity> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('[AUTH_REPO] Registrando usuario: $email');
      
      final response = await _remote.register(
        RegisterRequestDto(
          nombre: name,
          email: email,
          password: password,
        ),
      );

      AppLogger.info('[AUTH_REPO] ✅ Usuario registrado: ${response.user?.email}');

      // Después del registro exitoso, hacer login automático
      return await login(email, password);
    } catch (e) {
      AppLogger.error('[AUTH_REPO] ❌ Error en registro', e);
      throw DioErrorMapper.map(e);
    }
  }
}

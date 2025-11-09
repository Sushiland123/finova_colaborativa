import '../datasources/remote/auth_remote_datasource.dart';
import '../dtos/auth_dtos.dart';
import '../../core/errors/dio_error_mapper.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/logger.dart';

class AuthRepository {
  final AuthRemoteDataSource _remote;
  final DioClient _dioClient;

  AuthRepository(this._remote, this._dioClient);

  Future<LoginResponseDto> login(String email, String password) async {
    try {
      final response = await _remote.login(LoginRequestDto(email: email, password: password));
      if (response.tokens.accessToken.isEmpty || response.tokens.refreshToken.isEmpty) {
        AppLogger.warning('[AUTH] Tokens vacíos tras login. ¿Coincide el JSON con lo esperado? access="${response.tokens.accessToken}" refresh="${response.tokens.refreshToken}"');
      }
      await _dioClient.saveToken(response.tokens.accessToken);
      await _dioClient.saveRefreshToken(response.tokens.refreshToken);
      return response;
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  Future<void> logout() async {
    AppLogger.info('[AUTH] Repository.logout → llamando /auth/logout');
    try {
      await _remote.logout();
      AppLogger.info('[AUTH] /auth/logout OK');
    } catch (e) {
      AppLogger.warning('[AUTH] /auth/logout falló: $e');
    } finally {
      // Asegura limpieza local aunque el backend falle o devuelva 401
      await _dioClient.clearTokens();
      AppLogger.info('[AUTH] Tokens limpiados en storage');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _dioClient.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAccessToken() => _dioClient.getToken();
}

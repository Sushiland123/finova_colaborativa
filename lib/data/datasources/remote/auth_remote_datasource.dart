import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_client.dart';
import '../../dtos/auth_dtos.dart';

class AuthRemoteDataSource {
  final DioClient _client;
  AuthRemoteDataSource(this._client);

  Future<LoginResponseDto> login(LoginRequestDto dto) async {
    try {
      final resp = await _client.dio.post('/auth/login', data: dto.toJson());
      if (resp.data is Map<String, dynamic>) {
        return LoginResponseDto.fromJson(resp.data as Map<String, dynamic>);
      }
      throw NetworkError(NetworkErrorType.unknown, 'Respuesta inválida');
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  Future<AuthTokensDto> refresh(String refreshToken) async {
    try {
      final resp = await _client.dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      if (resp.data is Map<String, dynamic>) {
        return AuthTokensDto.fromJson(resp.data as Map<String, dynamic>);
      }
      throw NetworkError(NetworkErrorType.unknown, 'Respuesta inválida');
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  Future<RegisterResponseDto> register(RegisterRequestDto dto) async {
    try {
      final resp = await _client.dio.post('/auth/register', data: dto.toJson());
      if (resp.data is Map<String, dynamic>) {
        return RegisterResponseDto.fromJson(resp.data as Map<String, dynamic>);
      }
      throw NetworkError(NetworkErrorType.unknown, 'Respuesta inválida');
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }
}

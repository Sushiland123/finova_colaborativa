import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // Claves centralizadas para evitar strings mágicos
  static const String _kAccessTokenKey = 'access_token';
  static const String _kRefreshTokenKey = 'refresh_token';
  bool _isLoggingOut = false; // bandera para inhibir refresh durante logout
  
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.connectionTimeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: ApiConfig.defaultHeaders,
      ),
    );
    
    // Interceptores
    _dio.interceptors.addAll([
      // Logger para desarrollo
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
      
      // Interceptor de autenticación + refresh controlado
      InterceptorsWrapper(
  onRequest: (options, handler) async {
          // Si estamos en logout, sólo permitir token para el propio endpoint /auth/logout
          final token = await _storage.read(key: _kAccessTokenKey);
          // Usar la URI final para detectar correctamente prefijos/baseUrl
          final String fullPath = options.uri.path; // e.g. /api/v1/auth/logout
          final bool isLogoutEndpoint = fullPath.contains('/auth/logout');
          if (_isLoggingOut && !isLogoutEndpoint) {
            AppLogger.info('[HTTP][AUTH] omitido Authorization (logout en progreso) path=${fullPath}');
          } else if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            AppLogger.info('[HTTP][AUTH] Authorization adjunto path=${fullPath} tokenLen=${token.length}');
          } else {
            AppLogger.warning('[HTTP][AUTH] Sin token disponible para path=${fullPath}');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Si estamos en logout, nunca intentamos refresh
          if (!_isLoggingOut && error.response?.statusCode == 401) {
            // Evitar bucles infinitos
            final hasRetried = error.requestOptions.extra['__retried'] == true;
            if (!hasRetried) {
              AppLogger.warning('Token expirado, intentando refrescar...');
              try {
                final newToken = await _refreshAccessToken();
                if (newToken != null) {
                  // Reintentar la solicitud original con nuevo token
                  final RequestOptions req = error.requestOptions;
                  req.headers['Authorization'] = 'Bearer $newToken';
                  req.extra = Map<String, dynamic>.from(req.extra)..['__retried'] = true;
                  final Response<dynamic> response = await _dio.fetch<dynamic>(req);
                  return handler.resolve(response);
                }
              } catch (e) {
                AppLogger.error('No se pudo refrescar el token', e);
              }
            }
          }
          handler.next(error);
        },
      ),
    ]);
  }
  
  Dio get dio => _dio;
  
  // Métodos helper
  Future<void> saveToken(String token) async {
    await _storage.write(key: _kAccessTokenKey, value: token);
    AppLogger.info('[AUTH] Access token guardado (${token.length} chars)');
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _kRefreshTokenKey, value: token);
    AppLogger.info('[AUTH] Refresh token guardado (${token.length} chars)');
  }
  
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
    AppLogger.warning('[AUTH] Tokens eliminados');
  }

  // Control del ciclo de logout para evitar re-autenticación involuntaria
  void beginLogout() {
    if (!_isLoggingOut) {
      _isLoggingOut = true;
      AppLogger.info('[AUTH] DioClient.beginLogout → bandera activada');
    }
  }

  void endLogout() {
    if (_isLoggingOut) {
      _isLoggingOut = false;
      AppLogger.info('[AUTH] DioClient.endLogout → bandera desactivada');
    }
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: _kAccessTokenKey);
  }

  Future<String?> _getRefreshToken() async {
    return await _storage.read(key: _kRefreshTokenKey);
  }

  /// Llama al endpoint de refresh y actualiza los tokens en storage. Devuelve el nuevo access token.
  Future<String?> _refreshAccessToken() async {
    final refresh = await _getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      AppLogger.warning('No hay refresh token disponible');
      return null;
    }

    // Usamos un Dio temporal sin interceptores para evitar recursión
    final Dio tmp = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.connectionTimeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: ApiConfig.defaultHeaders,
      ),
    );

    try {
      final resp = await tmp.post('/auth/refresh', data: {
        'refreshToken': refresh,
      });
      final data = resp.data is Map ? resp.data as Map : <String, dynamic>{};
      final String? accessToken = data['accessToken'] as String?;
      final String? refreshToken = data['refreshToken'] as String?;
      if (accessToken != null) {
        await saveToken(accessToken);
      }
      if (refreshToken != null) {
        await saveRefreshToken(refreshToken);
      }
      AppLogger.info('[AUTH] Refresh exitoso. Nuevo access token length=${accessToken?.length ?? 0}');
      return accessToken;
    } catch (e) {
      // Limpiar si refresh falla
      await clearTokens();
      rethrow;
    }
  }

  /// DEBUG ONLY: fuerza tokens inválidos para probar flujo de refresco.
  Future<void> debugInvalidateAccessToken() async {
    await _storage.write(key: _kAccessTokenKey, value: 'invalid');
    AppLogger.warning('[AUTH][DEBUG] Access token invalidado manualmente');
  }
}
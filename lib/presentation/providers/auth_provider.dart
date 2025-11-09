import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/providers/domain_providers.dart';
import '../../core/providers/dio_provider.dart';
import '../../core/utils/logger.dart';
import '../../core/network/dio_client.dart';

/// Estado de autenticación para UI
/// Mantiene compatibilidad con código existente
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? userId,
    String? email,
    String? error,
  }) => AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        userId: userId ?? this.userId,
        email: email ?? this.email,
        error: error,
      );

  /// Crear desde AuthEntity del dominio
  factory AuthState.fromEntity(AuthEntity entity, {bool isLoading = false, String? error}) {
    return AuthState(
      isLoading: isLoading,
      isAuthenticated: entity.isAuthenticated,
      userId: entity.user?.id,
      email: entity.user?.email,
      error: error,
    );
  }
}

/// Notifier refactorizado usando Clean Architecture
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final IsLoggedInUseCase _isLoggedInUseCase;
  final DioClient _dioClient;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required IsLoggedInUseCase isLoggedInUseCase,
    required DioClient dioClient,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _isLoggedInUseCase = isLoggedInUseCase,
        _dioClient = dioClient,
        super(const AuthState());

  /// Login usando Use Case
  Future<void> login(String email, String password) async {
    AppLogger.info('[AUTH_NOTIFIER] 🔐 Iniciando login...');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authEntity = await _loginUseCase.call(
        LoginParams(email: email, password: password),
      );

      state = AuthState.fromEntity(authEntity);
      AppLogger.info('[AUTH_NOTIFIER] ✅ Login exitoso: ${authEntity.user?.email}');
    } catch (e) {
      AppLogger.error('[AUTH_NOTIFIER] ❌ Error en login', e);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.toString(),
      );
    }
  }

  /// Logout usando Use Case
  Future<void> logout() async {
    AppLogger.info('[AUTH_NOTIFIER] 🚪 ============ LOGOUT INICIADO ============');
    AppLogger.info('[AUTH_NOTIFIER] Estado ANTES: isAuthenticated=${state.isAuthenticated}');
    
    state = state.copyWith(isLoading: true, error: null);
    _dioClient.beginLogout();
    
    try {
      final tokenBefore = await _dioClient.getToken();
      if (tokenBefore == null) {
        AppLogger.warning('[AUTH_NOTIFIER] No había access token al iniciar logout');
      } else {
        AppLogger.info('[AUTH_NOTIFIER] Token presente, ejecutando logout...');
      }

      // Ejecutar Use Case
      await _logoutUseCase.call();
      AppLogger.info('[AUTH_NOTIFIER] ✅ Logout exitoso');
    } catch (e) {
      // Error es aceptable (ej: token expirado)
      AppLogger.warning('[AUTH_NOTIFIER] ⚠️ Error en logout remoto (continuamos): $e');
    } finally {
      // Limpieza local garantizada
      AppLogger.info('[AUTH_NOTIFIER] 🧹 Limpiando estado local...');
      await _dioClient.clearTokens();
      state = const AuthState(); // Reset completo
      _dioClient.endLogout();
      AppLogger.info('[AUTH_NOTIFIER] Estado DESPUÉS: isAuthenticated=${state.isAuthenticated}');
      AppLogger.info('[AUTH_NOTIFIER] 🚪 ============ LOGOUT COMPLETADO ============');
    }
  }

  /// Verificar sesión existente usando Use Case
  Future<void> checkSession() async {
    AppLogger.info('[AUTH_NOTIFIER] 🔍 ============ CHECK SESSION ============');
    
    try {
      final isLoggedIn = await _isLoggedInUseCase.call();
      AppLogger.info('[AUTH_NOTIFIER] 🔍 Use Case reporta logged=$isLoggedIn');
      
      if (isLoggedIn) {
        AppLogger.info('[AUTH_NOTIFIER] ✅ Restaurando sesión');
        state = state.copyWith(isAuthenticated: true);
      } else {
        AppLogger.info('[AUTH_NOTIFIER] ❌ No hay sesión');
      }
    } catch (e) {
      AppLogger.error('[AUTH_NOTIFIER] ❌ Error verificando sesión', e);
    }
    
    AppLogger.info('[AUTH_NOTIFIER] 🔍 Estado final: isAuthenticated=${state.isAuthenticated}');
    AppLogger.info('[AUTH_NOTIFIER] 🔍 ============ CHECK SESSION FIN ============');
  }
}

// ============ PROVIDERS ============

/// Provider refactorizado usando Clean Architecture
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    isLoggedInUseCase: ref.watch(isLoggedInUseCaseProvider),
    dioClient: ref.watch(dioClientProvider),
  );
});

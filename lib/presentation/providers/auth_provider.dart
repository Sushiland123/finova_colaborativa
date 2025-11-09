import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../core/providers/dio_provider.dart';
import '../../core/errors/dio_error_mapper.dart';
import '../../core/utils/logger.dart';
import '../../core/network/dio_client.dart';

// Estado de autenticación
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
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final DioClient _dioClient;
  AuthNotifier(this._repository, this._dioClient) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _repository.login(email, password);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: resp.user?.id,
        email: resp.user?.email ?? email,
      );
    } catch (e) {
      final mapped = DioErrorMapper.map(e);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: mapped.message,
      );
    }
  }

  Future<void> logout() async {
    AppLogger.info('[AUTH] ============ LOGOUT INICIADO ============');
    AppLogger.info('[AUTH] Estado ANTES: isAuthenticated=${state.isAuthenticated}, isLoading=${state.isLoading}');
    // Marcamos loading pero mantenemos isAuthenticated hasta confirmar logout remoto
    state = state.copyWith(isLoading: true, error: null);
    _dioClient.beginLogout();
    try {
      final tokenBefore = await _dioClient.getToken();
      if (tokenBefore == null) {
        AppLogger.warning('[AUTH] No había access token al iniciar logout');
      } else {
        AppLogger.info('[AUTH] Access token presente (${tokenBefore.substring(0, 20)}...), intentaremos /auth/logout');
      }
      await _repository.logout(); // Esto intentará revocar refresh token en backend
      AppLogger.info('[AUTH] ✅ Logout remoto OK');
    } catch (e) {
      // 401 aquí es aceptable si el token ya expiró; igual seguimos con limpieza local
      AppLogger.warning('[AUTH] ⚠️ Logout remoto falló o devolvió error: $e (continuamos)');
    } finally {
      AppLogger.info('[AUTH] 🧹 Limpiando tokens locales...');
      await _dioClient.clearTokens(); // Limpieza final asegurada
      AppLogger.info('[AUTH] 🧹 Reseteando state...');
      state = const AuthState(); // Reset completo
      _dioClient.endLogout();
      AppLogger.info('[AUTH] Estado DESPUÉS: isAuthenticated=${state.isAuthenticated}, isLoading=${state.isLoading}');
      AppLogger.info('[AUTH] ============ LOGOUT COMPLETADO ============');
    }
  }

  Future<void> checkSession() async {
    AppLogger.info('[AUTH] 🔍 ============ CHECK SESSION ============');
    final logged = await _repository.isLoggedIn();
    AppLogger.info('[AUTH] 🔍 Repository reporta logged=$logged');
    if (logged) {
      AppLogger.info('[AUTH] ✅ Restaurando sesión (isAuthenticated → true)');
      state = state.copyWith(isAuthenticated: true);
    } else {
      AppLogger.info('[AUTH] ❌ No hay sesión para restaurar');
    }
    AppLogger.info('[AUTH] 🔍 Estado final: isAuthenticated=${state.isAuthenticated}');
    AppLogger.info('[AUTH] 🔍 ============ CHECK SESSION FIN ============');
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final remote = AuthRemoteDataSource(dioClient);
  return AuthRepository(remote, dioClient);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final dioClient = ref.watch(dioClientProvider);
  return AuthNotifier(repo, dioClient);
});

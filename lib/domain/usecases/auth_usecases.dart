import '../entities/auth_entity.dart';
import '../repositories/i_auth_repository.dart';
import 'usecase.dart';

/// Use Case: Login
class LoginUseCase extends UseCase<AuthEntity, LoginParams> {
  final IAuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<AuthEntity> call(LoginParams params) async {
    // Validaciones de negocio
    if (params.email.isEmpty || !params.email.contains('@')) {
      throw Exception('Email inválido');
    }

    if (params.password.isEmpty || params.password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    return await _repository.login(params.email, params.password);
  }
}

class LoginParams {
  final String email;
  final String password;

  LoginParams({required this.email, required this.password});
}

/// Use Case: Logout
class LogoutUseCase extends NoParamsUseCase<void> {
  final IAuthRepository _repository;

  LogoutUseCase(this._repository);

  @override
  Future<void> call() async {
    return await _repository.logout();
  }
}

/// Use Case: Verificar si está logueado
class IsLoggedInUseCase extends NoParamsUseCase<bool> {
  final IAuthRepository _repository;

  IsLoggedInUseCase(this._repository);

  @override
  Future<bool> call() async {
    return await _repository.isLoggedIn();
  }
}

/// Use Case: Obtener usuario actual
class GetCurrentUserUseCase extends NoParamsUseCase<UserEntity?> {
  final IAuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  @override
  Future<UserEntity?> call() async {
    return await _repository.getCurrentUser();
  }
}

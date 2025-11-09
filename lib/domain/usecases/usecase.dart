/// Clase base para todos los Use Cases
/// 
/// Los Use Cases encapsulan la lógica de negocio de la aplicación.
/// Son independientes de frameworks y detalles de implementación.
/// 
/// Type parameters:
/// - [Type]: El tipo de retorno del use case
/// - [Params]: Los parámetros requeridos para ejecutar el use case
abstract class UseCase<Type, Params> {
  /// Ejecuta el caso de uso
  Future<Type> call(Params params);
}

/// Use Case sin parámetros
abstract class NoParamsUseCase<Type> {
  Future<Type> call();
}

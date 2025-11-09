import '../entities/transaction_entity.dart';
import '../repositories/i_transaction_repository.dart';
import 'usecase.dart';

/// Use Case: Obtener todas las transacciones
class GetTransactionsUseCase extends NoParamsUseCase<List<TransactionEntity>> {
  final ITransactionRepository _repository;

  GetTransactionsUseCase(this._repository);

  @override
  Future<List<TransactionEntity>> call() async {
    return await _repository.getTransactions();
  }
}

/// Use Case: Crear una transacción
class CreateTransactionUseCase extends UseCase<TransactionEntity, CreateTransactionParams> {
  final ITransactionRepository _repository;

  CreateTransactionUseCase(this._repository);

  @override
  Future<TransactionEntity> call(CreateTransactionParams params) async {
    // Aquí puedes agregar validaciones de negocio
    if (params.transaction.amount <= 0) {
      throw Exception('El monto debe ser mayor a 0');
    }

    return await _repository.createTransaction(params.transaction);
  }
}

class CreateTransactionParams {
  final TransactionEntity transaction;

  CreateTransactionParams({required this.transaction});
}

/// Use Case: Actualizar una transacción
class UpdateTransactionUseCase extends UseCase<TransactionEntity, UpdateTransactionParams> {
  final ITransactionRepository _repository;

  UpdateTransactionUseCase(this._repository);

  @override
  Future<TransactionEntity> call(UpdateTransactionParams params) async {
    if (params.transaction.amount <= 0) {
      throw Exception('El monto debe ser mayor a 0');
    }

    return await _repository.updateTransaction(params.transaction);
  }
}

class UpdateTransactionParams {
  final TransactionEntity transaction;

  UpdateTransactionParams({required this.transaction});
}

/// Use Case: Eliminar una transacción
class DeleteTransactionUseCase extends UseCase<void, DeleteTransactionParams> {
  final ITransactionRepository _repository;

  DeleteTransactionUseCase(this._repository);

  @override
  Future<void> call(DeleteTransactionParams params) async {
    return await _repository.deleteTransaction(params.transactionId);
  }
}

class DeleteTransactionParams {
  final String transactionId;

  DeleteTransactionParams({required this.transactionId});
}

/// Use Case: Obtener estadísticas
class GetTransactionStatisticsUseCase extends NoParamsUseCase<TransactionStatistics> {
  final ITransactionRepository _repository;

  GetTransactionStatisticsUseCase(this._repository);

  @override
  Future<TransactionStatistics> call() async {
    return await _repository.getStatistics();
  }
}

/// Use Case: Obtener gastos por categoría
class GetExpensesByCategoryUseCase extends NoParamsUseCase<Map<TransactionCategoryEntity, double>> {
  final ITransactionRepository _repository;

  GetExpensesByCategoryUseCase(this._repository);

  @override
  Future<Map<TransactionCategoryEntity, double>> call() async {
    return await _repository.getExpensesByCategory();
  }
}

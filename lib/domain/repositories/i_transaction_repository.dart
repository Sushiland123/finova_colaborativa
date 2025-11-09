import '../entities/transaction_entity.dart';

/// Interfaz del repositorio de transacciones
/// Define el contrato que debe cumplir cualquier implementación
abstract class ITransactionRepository {
  /// Obtener todas las transacciones del usuario
  Future<List<TransactionEntity>> getTransactions();

  /// Obtener una transacción por ID
  Future<TransactionEntity?> getTransactionById(String id);

  /// Crear una nueva transacción
  Future<TransactionEntity> createTransaction(TransactionEntity transaction);

  /// Actualizar una transacción existente
  Future<TransactionEntity> updateTransaction(TransactionEntity transaction);

  /// Eliminar una transacción
  Future<void> deleteTransaction(String id);

  /// Obtener estadísticas de transacciones
  Future<TransactionStatistics> getStatistics();

  /// Obtener gastos por categoría
  Future<Map<TransactionCategoryEntity, double>> getExpensesByCategory();
}

/// Objeto de valor para estadísticas
class TransactionStatistics {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final int transactionCount;

  const TransactionStatistics({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.transactionCount,
  });

  factory TransactionStatistics.empty() {
    return const TransactionStatistics(
      totalIncome: 0.0,
      totalExpenses: 0.0,
      balance: 0.0,
      transactionCount: 0,
    );
  }
}

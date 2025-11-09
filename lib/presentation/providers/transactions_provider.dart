import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../domain/providers/domain_providers.dart';
import '../../core/utils/logger.dart';

/// Estado para las transacciones
class TransactionsState {
  final List<TransactionEntity> transactions;
  final TransactionStatistics statistics;
  final Map<TransactionCategoryEntity, double> expensesByCategory;
  final bool isLoading;
  final String? error;

  TransactionsState({
    this.transactions = const [],
    TransactionStatistics? statistics,
    this.expensesByCategory = const {},
    this.isLoading = false,
    this.error,
  }) : statistics = statistics ?? TransactionStatistics.empty();

  TransactionsState copyWith({
    List<TransactionEntity>? transactions,
    TransactionStatistics? statistics,
    Map<TransactionCategoryEntity, double>? expensesByCategory,
    bool? isLoading,
    String? error,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      statistics: statistics ?? this.statistics,
      expensesByCategory: expensesByCategory ?? this.expensesByCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier para gestionar transacciones usando Clean Architecture
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final GetTransactionsUseCase _getTransactionsUseCase;
  final CreateTransactionUseCase _createTransactionUseCase;
  final UpdateTransactionUseCase _updateTransactionUseCase;
  final DeleteTransactionUseCase _deleteTransactionUseCase;
  final GetTransactionStatisticsUseCase _getStatisticsUseCase;
  final GetExpensesByCategoryUseCase _getExpensesByCategoryUseCase;

  TransactionsNotifier({
    required GetTransactionsUseCase getTransactionsUseCase,
    required CreateTransactionUseCase createTransactionUseCase,
    required UpdateTransactionUseCase updateTransactionUseCase,
    required DeleteTransactionUseCase deleteTransactionUseCase,
    required GetTransactionStatisticsUseCase getStatisticsUseCase,
    required GetExpensesByCategoryUseCase getExpensesByCategoryUseCase,
  })  : _getTransactionsUseCase = getTransactionsUseCase,
        _createTransactionUseCase = createTransactionUseCase,
        _updateTransactionUseCase = updateTransactionUseCase,
        _deleteTransactionUseCase = deleteTransactionUseCase,
        _getStatisticsUseCase = getStatisticsUseCase,
        _getExpensesByCategoryUseCase = getExpensesByCategoryUseCase,
        super(TransactionsState());

  /// Cargar todas las transacciones
  Future<void> loadTransactions() async {
    try {
      AppLogger.info('[TRANSACTIONS_NOTIFIER] 🔄 Cargando transacciones...');
      state = state.copyWith(isLoading: true, error: null);

      final transactions = await _getTransactionsUseCase.call();
      final statistics = await _getStatisticsUseCase.call();
      final expensesByCategory = await _getExpensesByCategoryUseCase.call();

      state = state.copyWith(
        transactions: transactions,
        statistics: statistics,
        expensesByCategory: expensesByCategory,
        isLoading: false,
      );

      AppLogger.info('[TRANSACTIONS_NOTIFIER] ✅ ${transactions.length} transacciones cargadas');
    } catch (e) {
      AppLogger.error('[TRANSACTIONS_NOTIFIER] ❌ Error cargando transacciones', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Crear una nueva transacción
  Future<void> createTransaction(TransactionEntity transaction) async {
    try {
      AppLogger.info('[TRANSACTIONS_NOTIFIER] 📤 Creando transacción: ${transaction.title}');
      
      await _createTransactionUseCase.call(
        CreateTransactionParams(transaction: transaction),
      );

      // Recargar para actualizar la lista
      await loadTransactions();
      
      AppLogger.info('[TRANSACTIONS_NOTIFIER] ✅ Transacción creada');
    } catch (e) {
      AppLogger.error('[TRANSACTIONS_NOTIFIER] ❌ Error creando transacción', e);
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Actualizar una transacción existente
  Future<void> updateTransaction(TransactionEntity transaction) async {
    try {
      AppLogger.info('[TRANSACTIONS_NOTIFIER] 📝 Actualizando transacción: ${transaction.id}');
      
      await _updateTransactionUseCase.call(
        UpdateTransactionParams(transaction: transaction),
      );

      // Recargar para actualizar la lista
      await loadTransactions();
      
      AppLogger.info('[TRANSACTIONS_NOTIFIER] ✅ Transacción actualizada');
    } catch (e) {
      AppLogger.error('[TRANSACTIONS_NOTIFIER] ❌ Error actualizando transacción', e);
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Eliminar una transacción
  Future<void> deleteTransaction(String transactionId) async {
    try {
      AppLogger.info('[TRANSACTIONS_NOTIFIER] 🗑️ Eliminando transacción: $transactionId');
      
      await _deleteTransactionUseCase.call(
        DeleteTransactionParams(transactionId: transactionId),
      );

      // Recargar para actualizar la lista
      await loadTransactions();
      
      AppLogger.info('[TRANSACTIONS_NOTIFIER] ✅ Transacción eliminada');
    } catch (e) {
      AppLogger.error('[TRANSACTIONS_NOTIFIER] ❌ Error eliminando transacción', e);
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Filtrar transacciones por tipo
  List<TransactionEntity> getTransactionsByType(TransactionTypeEntity type) {
    return state.transactions.where((t) => t.type == type).toList();
  }

  /// Obtener porcentaje de una categoría
  double getCategoryPercentage(TransactionCategoryEntity category) {
    final total = state.statistics.totalExpenses;
    if (total == 0) return 0;
    
    final categoryAmount = state.expensesByCategory[category] ?? 0;
    return (categoryAmount / total) * 100;
  }
}

/// Provider para el notifier de transacciones
final transactionsNotifierProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier(
    getTransactionsUseCase: ref.watch(getTransactionsUseCaseProvider),
    createTransactionUseCase: ref.watch(createTransactionUseCaseProvider),
    updateTransactionUseCase: ref.watch(updateTransactionUseCaseProvider),
    deleteTransactionUseCase: ref.watch(deleteTransactionUseCaseProvider),
    getStatisticsUseCase: ref.watch(getTransactionStatisticsUseCaseProvider),
    getExpensesByCategoryUseCase: ref.watch(getExpensesByCategoryUseCaseProvider),
  );
});

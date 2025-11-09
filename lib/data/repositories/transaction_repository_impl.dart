import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../datasources/remote/transaction_remote_datasource.dart';
import '../database/database_service.dart';
import '../mappers/transaction_mapper.dart';
import '../../core/utils/logger.dart';

/// Implementación del repositorio de transacciones
/// 
/// Esta clase implementa la interfaz ITransactionRepository definida en domain.
/// Coordina entre las fuentes de datos remotas y locales.
class TransactionRepositoryImpl implements ITransactionRepository {
  final TransactionRemoteDataSource _remoteDataSource;
  final DatabaseService _databaseService;

  TransactionRepositoryImpl({
    required TransactionRemoteDataSource remoteDataSource,
    required DatabaseService databaseService,
  })  : _remoteDataSource = remoteDataSource,
        _databaseService = databaseService;

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    try {
      AppLogger.info('[REPO] Obteniendo transacciones desde backend...');
      
      // Intentar cargar desde backend primero
      final models = await _remoteDataSource.getTransactions();
      final entities = TransactionMapper.toEntityList(models);
      
      AppLogger.info('[REPO] ✅ ${entities.length} transacciones desde backend');
      
      // Guardar en cache local (segundo plano)
      _saveToLocalAsync(models);
      
      return entities;
    } catch (e) {
      // Fallback a datos locales
      AppLogger.warning('[REPO] ⚠️ Backend no disponible, usando cache local');
      final localModels = await _databaseService.getTransactions();
      return TransactionMapper.toEntityList(localModels);
    }
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    try {
      final models = await _remoteDataSource.getTransactions();
      final model = models.firstWhere((t) => t.id == id);
      return TransactionMapper.toEntity(model);
    } catch (e) {
      // Fallback a local
      final localModels = await _databaseService.getTransactions();
      try {
        final model = localModels.firstWhere((t) => t.id == id);
        return TransactionMapper.toEntity(model);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<TransactionEntity> createTransaction(TransactionEntity entity) async {
    try {
      AppLogger.info('[REPO] Creando transacción en backend...');
      
      final model = TransactionMapper.toModel(entity);
      final createdModel = await _remoteDataSource.createTransaction(model);
      
      // Guardar también en local
      await _databaseService.insertTransaction(createdModel);
      
      return TransactionMapper.toEntity(createdModel);
    } catch (e) {
      // Si backend falla, guardar solo local
      AppLogger.warning('[REPO] ⚠️ Error en backend, guardando solo local');
      final model = TransactionMapper.toModel(entity);
      await _databaseService.insertTransaction(model);
      return entity;
    }
  }

  @override
  Future<TransactionEntity> updateTransaction(TransactionEntity entity) async {
    try {
      final model = TransactionMapper.toModel(entity);
      final updatedModel = await _remoteDataSource.updateTransaction(entity.id, model);
      
      // Actualizar también en local
      await _databaseService.updateTransaction(updatedModel);
      
      return TransactionMapper.toEntity(updatedModel);
    } catch (e) {
      // Si backend falla, actualizar solo local
      final model = TransactionMapper.toModel(entity);
      await _databaseService.updateTransaction(model);
      return entity;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _remoteDataSource.deleteTransaction(id);
      await _databaseService.deleteTransaction(id);
    } catch (e) {
      // Si backend falla, eliminar solo local
      await _databaseService.deleteTransaction(id);
    }
  }

  @override
  Future<TransactionStatistics> getStatistics() async {
    try {
      // Obtener desde backend
      final models = await _remoteDataSource.getTransactions();
      return _calculateStatistics(TransactionMapper.toEntityList(models));
    } catch (e) {
      // Fallback a local
      final localModels = await _databaseService.getTransactions();
      return _calculateStatistics(TransactionMapper.toEntityList(localModels));
    }
  }

  @override
  Future<Map<TransactionCategoryEntity, double>> getExpensesByCategory() async {
    try {
      final models = await _remoteDataSource.getTransactions();
      final entities = TransactionMapper.toEntityList(models);
      return _calculateExpensesByCategory(entities);
    } catch (e) {
      final localModels = await _databaseService.getTransactions();
      final entities = TransactionMapper.toEntityList(localModels);
      return _calculateExpensesByCategory(entities);
    }
  }

  // Helpers privados
  TransactionStatistics _calculateStatistics(List<TransactionEntity> transactions) {
    double totalIncome = 0;
    double totalExpenses = 0;

    for (var transaction in transactions) {
      if (transaction.isIncome) {
        totalIncome += transaction.amount;
      } else if (transaction.isExpense) {
        totalExpenses += transaction.amount;
      }
    }

    return TransactionStatistics(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: totalIncome - totalExpenses,
      transactionCount: transactions.length,
    );
  }

  Map<TransactionCategoryEntity, double> _calculateExpensesByCategory(
      List<TransactionEntity> transactions) {
    final Map<TransactionCategoryEntity, double> expenses = {};

    for (var transaction in transactions) {
      if (transaction.isExpense) {
        expenses[transaction.category] = 
            (expenses[transaction.category] ?? 0.0) + transaction.amount;
      }
    }

    return expenses;
  }

  void _saveToLocalAsync(List models) {
    Future.microtask(() async {
      try {
        for (var model in models) {
          await _databaseService.insertTransaction(model);
        }
        AppLogger.info('[REPO] 💾 Cache local actualizado');
      } catch (e) {
        AppLogger.warning('[REPO] ⚠️ Error guardando cache: $e');
      }
    });
  }
}

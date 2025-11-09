import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../models/transaction_model.dart';

class TransactionRemoteDataSource {
  final DioClient _client;
  TransactionRemoteDataSource(this._client);

  /// Obtiene transacciones desde el backend
  Future<List<Transaction>> getTransactions() async {
    try {
      AppLogger.info('[REMOTE_TX] GET /transactions (inicio)');
      final resp = await _client.dio.get('/transactions');
      AppLogger.info('[REMOTE_TX] GET /transactions status=${resp.statusCode}');
      if (resp.data is List) {
        final list = (resp.data as List)
            .whereType<Map>()
            .map((e) => Transaction.fromBackend(Map<String, dynamic>.from(e)))
            .toList();
        AppLogger.info('[REMOTE_TX] ✅ ${list.length} transacciones recibidas desde backend');
        return list;
      } else if (resp.data is Map && (resp.data as Map)['data'] is List) {
        final raw = (resp.data as Map)['data'] as List;
        final list = raw
            .whereType<Map>()
            .map((e) => Transaction.fromBackend(Map<String, dynamic>.from(e)))
            .toList();
        AppLogger.info('[REMOTE_TX] ✅ ${list.length} transacciones (envuelto)');
        return list;
      }
      AppLogger.warning('[REMOTE_TX] ⚠️ Respuesta no es lista, devolviendo []');
      return [];
    } catch (e) {
      AppLogger.warning('[REMOTE_TX] ❌ Error GET /transactions: $e');
      throw DioErrorMapper.map(e);
    }
  }

  /// Crea una transacción en el backend
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      AppLogger.info('[REMOTE_TX] POST /transactions (inicio) body=${transaction.toJson()}');
      final resp = await _client.dio.post('/transactions', data: transaction.toJson());
      AppLogger.info('[REMOTE_TX] POST /transactions status=${resp.statusCode}');
      if (resp.data is Map<String, dynamic>) {
        final created = Transaction.fromBackend(resp.data as Map<String, dynamic>);
        AppLogger.info('[REMOTE_TX] ✅ Transacción creada id=${created.id}');
        return created;
      }
      throw NetworkError(NetworkErrorType.unknown, 'Respuesta inválida');
    } catch (e) {
      AppLogger.warning('[REMOTE_TX] ❌ Error POST /transactions: $e');
      throw DioErrorMapper.map(e);
    }
  }

  /// Actualiza una transacción existente
  Future<Transaction> updateTransaction(String id, Transaction transaction) async {
    try {
      AppLogger.info('[REMOTE_TX] PATCH /transactions/$id (inicio)');
      final resp = await _client.dio.patch('/transactions/$id', data: transaction.toJson(includeId: true));
      AppLogger.info('[REMOTE_TX] PATCH /transactions/$id status=${resp.statusCode}');
      if (resp.data is Map<String, dynamic>) {
        final updated = Transaction.fromBackend(resp.data as Map<String, dynamic>);
        AppLogger.info('[REMOTE_TX] ✅ Transacción actualizada id=${updated.id}');
        return updated;
      } else if (resp.data is Map && (resp.data as Map)['data'] is Map) {
        final inner = (resp.data as Map)['data'] as Map<String, dynamic>;
        final updated = Transaction.fromBackend(inner);
        AppLogger.info('[REMOTE_TX] ✅ Transacción actualizada (envuelta) id=${updated.id}');
        return updated;
      }
      throw NetworkError(NetworkErrorType.unknown, 'Respuesta inválida');
    } catch (e) {
      AppLogger.warning('[REMOTE_TX] ❌ Error PATCH /transactions/$id: $e');
      throw DioErrorMapper.map(e);
    }
  }

  /// Elimina una transacción
  Future<void> deleteTransaction(String id) async {
    try {
      AppLogger.info('[REMOTE_TX] DELETE /transactions/$id (inicio)');
      await _client.dio.delete('/transactions/$id');
      AppLogger.info('[REMOTE_TX] ✅ Transacción eliminada id=$id');
    } catch (e) {
      AppLogger.warning('[REMOTE_TX] ❌ Error DELETE /transactions/$id: $e');
      throw DioErrorMapper.map(e);
    }
  }
}

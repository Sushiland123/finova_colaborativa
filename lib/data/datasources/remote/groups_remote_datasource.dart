import 'package:dio/dio.dart';
import '../../models/group_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';

class GroupsRemoteDataSource {
  final DioClient _dioClient;

  GroupsRemoteDataSource(this._dioClient);

  /// Crear un nuevo grupo en el backend
  /// POST /groups
  Future<Group> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      AppLogger.info('[GROUPS_API] 📤 Creando grupo: $name');
      
      final response = await _dioClient.dio.post(
        '/groups',
        data: {
          'name': name,
          'description': description,
          // memberIds es opcional - el backend agrega automáticamente al creador
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.info('[GROUPS_API] ✅ Grupo creado exitosamente');
        return Group.fromBackend(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al crear grupo: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error en createGroup', e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error inesperado en createGroup', e);
      rethrow;
    }
  }

  /// Obtener todos los grupos del usuario autenticado
  /// GET /groups/me
  Future<List<Group>> getUserGroups() async {
    try {
      AppLogger.info('[GROUPS_API] 📥 Obteniendo grupos del usuario...');
      
      final response = await _dioClient.dio.get('/groups/me');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        AppLogger.info('[GROUPS_API] ✅ Grupos obtenidos: ${data.length}');
        
        return data
            .map((json) => Group.fromBackend(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al obtener grupos: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error en getUserGroups', e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error inesperado en getUserGroups', e);
      rethrow;
    }
  }

  /// Unirse a un grupo usando el código de invitación
  /// POST /groups/join
  Future<Group> joinGroup(String inviteCode) async {
    try {
      AppLogger.info('[GROUPS_API] 📤 Uniéndose a grupo con código: $inviteCode');
      
      final response = await _dioClient.dio.post(
        '/groups/join',
        data: {
          'inviteCode': inviteCode,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('[GROUPS_API] ✅ Unido al grupo exitosamente');
        return Group.fromBackend(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Error al unirse al grupo: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error en joinGroup', e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error inesperado en joinGroup', e);
      rethrow;
    }
  }

  /// Obtener gastos de un grupo específico
  /// GET /groups/:id/expenses
  Future<List<GroupExpense>> getGroupExpenses(String groupId) async {
    try {
      AppLogger.info('[GROUPS_API] 📥 Obteniendo gastos del grupo: $groupId');
      
      final response = await _dioClient.dio.get('/groups/$groupId/expenses');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        AppLogger.info('[GROUPS_API] ✅ Gastos obtenidos: ${data.length}');
        
        return data
            .map((json) => GroupExpense.fromBackend(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al obtener gastos: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error en getGroupExpenses', e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error inesperado en getGroupExpenses', e);
      rethrow;
    }
  }

  /// Obtener balances de un grupo específico
  /// GET /groups/:id/balances
  Future<Map<String, dynamic>> getGroupBalances(String groupId) async {
    try {
      AppLogger.info('[GROUPS_API] 📥 Obteniendo balances del grupo: $groupId');
      
      final response = await _dioClient.dio.get('/groups/$groupId/balances');

      if (response.statusCode == 200) {
        AppLogger.info('[GROUPS_API] ✅ Balances obtenidos');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Error al obtener balances: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error en getGroupBalances', e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error inesperado en getGroupBalances', e);
      rethrow;
    }
  }

  /// Agregar un gasto al grupo
  /// POST /groups/expenses
  Future<Map<String, dynamic>> addGroupExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    String? description,
    Map<String, double>? splits,
    DateTime? date,
  }) async {
    try {
      AppLogger.info('[GROUPS_API] 📤 Agregando gasto al grupo: $groupId');
      
      final response = await _dioClient.dio.post(
        '/groups/expenses',
        data: {
          'groupId': groupId,
          'title': title,
          'amount': amount,
          'paidBy': paidBy,
          if (description != null) 'description': description,
          if (splits != null) 'splits': splits,
          'date': (date ?? DateTime.now()).toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.info('[GROUPS_API] ✅ Gasto agregado exitosamente');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Error al agregar gasto: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error en addGroupExpense', e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error inesperado en addGroupExpense', e);
      rethrow;
    }
  }

  /// Liquidar deuda en un grupo
  /// POST /groups/:id/settle
  Future<Map<String, dynamic>> settleGroupDebt({
    required String groupId,
    String? expenseId,
    String? fromUserId,
    String? toUserId,
    double? amount,
  }) async {
    try {
      AppLogger.info('[GROUPS_API] 📤 Liquidando deuda en grupo: $groupId');
      
      final response = await _dioClient.dio.post(
        '/groups/$groupId/settle',
        data: {
          if (expenseId != null) 'expenseId': expenseId,
          if (fromUserId != null) 'fromUserId': fromUserId,
          if (toUserId != null) 'toUserId': toUserId,
          if (amount != null) 'amount': amount,
        },
      );

      if (response.statusCode == 200) {
        AppLogger.info('[GROUPS_API] ✅ Deuda liquidada exitosamente');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Error al liquidar deuda: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error en settleGroupDebt', e);
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('[GROUPS_API] ❌ Error inesperado en settleGroupDebt', e);
      rethrow;
    }
  }

  /// Manejo centralizado de errores de Dio
  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      String errorMessage = 'Error del servidor';
      
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'].toString();
      } else if (data is String) {
        errorMessage = data;
      }
      
      switch (statusCode) {
        case 400:
          return Exception('Solicitud inválida: $errorMessage');
        case 401:
          return Exception('No autorizado. Por favor inicia sesión nuevamente.');
        case 403:
          return Exception('No tienes permiso para realizar esta acción');
        case 404:
          return Exception('Recurso no encontrado: $errorMessage');
        case 409:
          return Exception('Conflicto: $errorMessage');
        case 500:
          return Exception('Error del servidor. Intenta nuevamente más tarde.');
        default:
          return Exception('Error: $errorMessage');
      }
    } else {
      // Error de conexión
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Exception('Tiempo de espera agotado. Verifica tu conexión.');
      } else if (e.type == DioExceptionType.connectionError) {
        return Exception('Error de conexión. Verifica tu internet.');
      } else {
        return Exception('Error de red: ${e.message}');
      }
    }
  }
}

import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/i_group_repository.dart';
import '../datasources/remote/groups_remote_datasource.dart';
import '../mappers/group_mapper.dart';
import '../../core/utils/logger.dart';

/// Implementación del repositorio de grupos
class GroupRepositoryImpl implements IGroupRepository {
  final GroupsRemoteDataSource _remoteDataSource;

  GroupRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<GroupEntity>> getUserGroups() async {
    try {
      AppLogger.info('[GROUP_REPOSITORY] Obteniendo grupos del usuario...');
      final groups = await _remoteDataSource.getUserGroups();
      final entities = GroupMapper.toEntityList(groups);
      AppLogger.info('[GROUP_REPOSITORY] ✅ ${entities.length} grupos obtenidos');
      return entities;
    } catch (e) {
      AppLogger.error('[GROUP_REPOSITORY] ❌ Error obteniendo grupos', e);
      rethrow;
    }
  }

  @override
  Future<GroupEntity?> getGroupById(String id) async {
    try {
      AppLogger.info('[GROUP_REPOSITORY] Obteniendo grupo: $id');
      final groups = await _remoteDataSource.getUserGroups();
      final group = groups.where((g) => g.id == id).firstOrNull;
      
      if (group == null) {
        AppLogger.warning('[GROUP_REPOSITORY] ⚠️ Grupo no encontrado: $id');
        return null;
      }
      
      final entity = GroupMapper.toEntity(group);
      AppLogger.info('[GROUP_REPOSITORY] ✅ Grupo encontrado: ${entity.name}');
      return entity;
    } catch (e) {
      AppLogger.error('[GROUP_REPOSITORY] ❌ Error obteniendo grupo', e);
      rethrow;
    }
  }

  @override
  Future<GroupEntity> createGroup({
    required String name,
    required String description,
    required GroupTypeEntity type,
  }) async {
    try {
      AppLogger.info('[GROUP_REPOSITORY] Creando grupo: $name');
      
      final group = await _remoteDataSource.createGroup(
        name: name,
        description: description,
      );
      
      final entity = GroupMapper.toEntity(group);
      AppLogger.info('[GROUP_REPOSITORY] ✅ Grupo creado: ${entity.id}');
      return entity;
    } catch (e) {
      AppLogger.error('[GROUP_REPOSITORY] ❌ Error creando grupo', e);
      rethrow;
    }
  }

  @override
  Future<GroupEntity> joinGroup(String inviteCode) async {
    try {
      AppLogger.info('[GROUP_REPOSITORY] Uniéndose a grupo con código: $inviteCode');
      
      final group = await _remoteDataSource.joinGroup(inviteCode);
      final entity = GroupMapper.toEntity(group);
      
      AppLogger.info('[GROUP_REPOSITORY] ✅ Unido al grupo: ${entity.name}');
      return entity;
    } catch (e) {
      AppLogger.error('[GROUP_REPOSITORY] ❌ Error uniéndose a grupo', e);
      rethrow;
    }
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    try {
      AppLogger.info('[GROUP_REPOSITORY] Saliendo del grupo: $groupId');
      
      // TODO: Implementar endpoint de salir del grupo en el backend
      // await _remoteDataSource.leaveGroup(groupId);
      
      AppLogger.warning('[GROUP_REPOSITORY] ⚠️ LeaveGroup no implementado en backend');
      throw UnimplementedError('LeaveGroup endpoint not available yet');
    } catch (e) {
      AppLogger.error('[GROUP_REPOSITORY] ❌ Error saliendo del grupo', e);
      rethrow;
    }
  }

  @override
  Future<GroupEntity> updateGroup(GroupEntity group) async {
    try {
      AppLogger.info('[GROUP_REPOSITORY] Actualizando grupo: ${group.id}');
      
      // TODO: Implementar endpoint de actualizar grupo en el backend
      // final model = GroupMapper.toModel(group);
      // final updated = await _remoteDataSource.updateGroup(model);
      // return GroupMapper.toEntity(updated);
      
      AppLogger.warning('[GROUP_REPOSITORY] ⚠️ UpdateGroup no implementado en backend');
      throw UnimplementedError('UpdateGroup endpoint not available yet');
    } catch (e) {
      AppLogger.error('[GROUP_REPOSITORY] ❌ Error actualizando grupo', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      AppLogger.info('[GROUP_REPOSITORY] Eliminando grupo: $groupId');
      
      // TODO: Implementar endpoint de eliminar grupo en el backend
      // await _remoteDataSource.deleteGroup(groupId);
      
      AppLogger.warning('[GROUP_REPOSITORY] ⚠️ DeleteGroup no implementado en backend');
      throw UnimplementedError('DeleteGroup endpoint not available yet');
    } catch (e) {
      AppLogger.error('[GROUP_REPOSITORY] ❌ Error eliminando grupo', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, double>> getGroupBalances(String groupId) async {
    try {
      AppLogger.info('[GROUP_REPOSITORY] Obteniendo balances del grupo: $groupId');
      
      final balances = await _remoteDataSource.getGroupBalances(groupId);
      
      // Convertir a Map<String, double>
      final result = <String, double>{};
      balances.forEach((key, value) {
        if (value is num) {
          result[key] = value.toDouble();
        }
      });
      
      AppLogger.info('[GROUP_REPOSITORY] ✅ Balances obtenidos: ${result.length} miembros');
      return result;
    } catch (e) {
      AppLogger.error('[GROUP_REPOSITORY] ❌ Error obteniendo balances', e);
      rethrow;
    }
  }
}

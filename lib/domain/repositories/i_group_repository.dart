import '../entities/group_entity.dart';

/// Interfaz del repositorio de grupos
abstract class IGroupRepository {
  /// Obtener todos los grupos del usuario
  Future<List<GroupEntity>> getUserGroups();

  /// Obtener un grupo por ID
  Future<GroupEntity?> getGroupById(String id);

  /// Crear un nuevo grupo
  Future<GroupEntity> createGroup({
    required String name,
    required String description,
    required GroupTypeEntity type,
  });

  /// Unirse a un grupo mediante código de invitación
  Future<GroupEntity> joinGroup(String inviteCode);

  /// Salir de un grupo
  Future<void> leaveGroup(String groupId);

  /// Actualizar información del grupo
  Future<GroupEntity> updateGroup(GroupEntity group);

  /// Eliminar un grupo (solo creador)
  Future<void> deleteGroup(String groupId);

  /// Obtener balances de un grupo
  Future<Map<String, double>> getGroupBalances(String groupId);
}

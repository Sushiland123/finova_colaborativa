import '../entities/group_entity.dart';
import '../repositories/i_group_repository.dart';
import 'usecase.dart';

/// Use Case: Obtener grupos del usuario
class GetUserGroupsUseCase extends NoParamsUseCase<List<GroupEntity>> {
  final IGroupRepository _repository;

  GetUserGroupsUseCase(this._repository);

  @override
  Future<List<GroupEntity>> call() async {
    return await _repository.getUserGroups();
  }
}

/// Use Case: Crear grupo
class CreateGroupUseCase extends UseCase<GroupEntity, CreateGroupParams> {
  final IGroupRepository _repository;

  CreateGroupUseCase(this._repository);

  @override
  Future<GroupEntity> call(CreateGroupParams params) async {
    // Validaciones de negocio
    if (params.name.isEmpty || params.name.length < 3) {
      throw Exception('El nombre del grupo debe tener al menos 3 caracteres');
    }

    return await _repository.createGroup(
      name: params.name,
      description: params.description,
      type: params.type,
    );
  }
}

class CreateGroupParams {
  final String name;
  final String description;
  final GroupTypeEntity type;

  CreateGroupParams({
    required this.name,
    required this.description,
    required this.type,
  });
}

/// Use Case: Unirse a grupo
class JoinGroupUseCase extends UseCase<GroupEntity, JoinGroupParams> {
  final IGroupRepository _repository;

  JoinGroupUseCase(this._repository);

  @override
  Future<GroupEntity> call(JoinGroupParams params) async {
    if (params.inviteCode.isEmpty || params.inviteCode.length < 6) {
      throw Exception('Código de invitación inválido');
    }

    return await _repository.joinGroup(params.inviteCode);
  }
}

class JoinGroupParams {
  final String inviteCode;

  JoinGroupParams({required this.inviteCode});
}

/// Use Case: Salir de grupo
class LeaveGroupUseCase extends UseCase<void, LeaveGroupParams> {
  final IGroupRepository _repository;

  LeaveGroupUseCase(this._repository);

  @override
  Future<void> call(LeaveGroupParams params) async {
    return await _repository.leaveGroup(params.groupId);
  }
}

class LeaveGroupParams {
  final String groupId;

  LeaveGroupParams({required this.groupId});
}

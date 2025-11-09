import '../../domain/entities/group_entity.dart';
import '../models/group_model.dart';

/// Mapper para convertir entre Group (Model) y GroupEntity (Domain)
class GroupMapper {
  /// Convierte de Model a Entity
  static GroupEntity toEntity(Group model) {
    return GroupEntity(
      id: model.id,
      name: model.name,
      description: model.description,
      creatorId: model.creatorId,
      memberIds: List<String>.from(model.memberIds),
      type: _mapGroupType(model.type),
      inviteCode: model.inviteCode,
      createdAt: model.createdAt,
      imageUrl: model.imageUrl,
      totalBalance: model.totalBalance,
    );
  }

  /// Convierte de Entity a Model
  static Group toModel(GroupEntity entity) {
    return Group(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      creatorId: entity.creatorId,
      memberIds: List<String>.from(entity.memberIds),
      type: _mapGroupTypeReverse(entity.type),
      inviteCode: entity.inviteCode,
      createdAt: entity.createdAt,
      imageUrl: entity.imageUrl,
      totalBalance: entity.totalBalance,
    );
  }

  /// Convierte lista de Models a Entities
  static List<GroupEntity> toEntityList(List<Group> models) {
    return models.map((model) => toEntity(model)).toList();
  }

  /// Convierte lista de Entities a Models
  static List<Group> toModelList(List<GroupEntity> entities) {
    return entities.map((entity) => toModel(entity)).toList();
  }

  /// Mapea GroupType (Model) → GroupTypeEntity (Entity)
  static GroupTypeEntity _mapGroupType(GroupType type) {
    switch (type) {
      case GroupType.family:
        return GroupTypeEntity.family;
      case GroupType.friends:
        return GroupTypeEntity.friends;
      case GroupType.roommates:
        return GroupTypeEntity.roommates;
      case GroupType.trip:
        return GroupTypeEntity.travel;
      case GroupType.project:
        return GroupTypeEntity.project;
      case GroupType.other:
        return GroupTypeEntity.other;
    }
  }

  /// Mapea GroupTypeEntity (Entity) → GroupType (Model)
  static GroupType _mapGroupTypeReverse(GroupTypeEntity type) {
    switch (type) {
      case GroupTypeEntity.family:
        return GroupType.family;
      case GroupTypeEntity.friends:
        return GroupType.friends;
      case GroupTypeEntity.roommates:
        return GroupType.roommates;
      case GroupTypeEntity.travel:
        return GroupType.trip;
      case GroupTypeEntity.project:
        return GroupType.project;
      case GroupTypeEntity.other:
        return GroupType.other;
    }
  }
}

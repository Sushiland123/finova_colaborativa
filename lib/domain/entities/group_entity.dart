/// Entidad del dominio: Grupo
class GroupEntity {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final GroupTypeEntity type;
  final String? inviteCode;
  final DateTime createdAt;
  final String? imageUrl;
  final double totalBalance;

  const GroupEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.type,
    this.inviteCode,
    required this.createdAt,
    this.imageUrl,
    this.totalBalance = 0.0,
  });

  GroupEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    List<String>? memberIds,
    GroupTypeEntity? type,
    String? inviteCode,
    DateTime? createdAt,
    String? imageUrl,
    double? totalBalance,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      type: type ?? this.type,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      totalBalance: totalBalance ?? this.totalBalance,
    );
  }
}

/// Tipos de grupo
enum GroupTypeEntity {
  friends,
  family,
  roommates,
  travel,
  project,
  other,
}

import 'package:uuid/uuid.dart';

enum GroupType {
  family,
  friends,
  roommates,
  trip,
  project,
  other
}

enum SplitType {
  equal,        // División igual entre todos
  percentage,   // Por porcentajes personalizados
  amount,       // Montos específicos por persona
  shares        // Por partes (ej: 2 partes para uno, 1 para otro)
}

// Modelo de Grupo
class Group {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final GroupType type;
  final String inviteCode;
  final DateTime createdAt;
  final String? imageUrl;
  double totalBalance;

  Group({
    String? id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.type,
    String? inviteCode,
    DateTime? createdAt,
    this.imageUrl,
    this.totalBalance = 0.0,
  })  : id = id ?? const Uuid().v4(),
        inviteCode = inviteCode ?? _generateInviteCode(),
        createdAt = createdAt ?? DateTime.now();

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[(random + i * 17) % chars.length];
    }
    return code;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds.join(','),
      'type': type.index,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'totalBalance': totalBalance,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      creatorId: map['creatorId'],
      memberIds: map['memberIds'].split(','),
      type: GroupType.values[map['type']],
      inviteCode: map['inviteCode'],
      createdAt: DateTime.parse(map['createdAt']),
      imageUrl: map['imageUrl'],
      totalBalance: map['totalBalance'] ?? 0.0,
    );
  }

  /// Crea un grupo desde la respuesta del backend NestJS.
  /// Estructura esperada:
  /// {
  ///   id: string,
  ///   name: string,
  ///   description: string,
  ///   creatorId: string,
  ///   memberIds: string[],
  ///   inviteCode: string,
  ///   totalBalance: number,
  ///   memberBalances: { userId: number, ... },
  ///   createdAt: ISO8601
  /// }
  factory Group.fromBackend(Map<String, dynamic> json) {
    // Fallback seguro para campos opcionales
    final rawMembers = json['memberIds'];
    List<String> members;
    if (rawMembers is List) {
      members = rawMembers.map((e) => e.toString()).toList();
    } else if (rawMembers is String) {
      members = rawMembers.split(',');
    } else {
      members = [];
    }

    return Group(
      id: json['id']?.toString(),
      name: json['name'] ?? 'Sin nombre',
      description: json['description'] ?? '',
      creatorId: json['creatorId']?.toString() ?? '',
      memberIds: members,
      type: GroupType.other, // El backend aún no expone el tipo; default other
      inviteCode: json['inviteCode']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      totalBalance: (json['totalBalance'] is num) ? (json['totalBalance'] as num).toDouble() : 0.0,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try { return DateTime.parse(value); } catch (_) {}
    }
    return DateTime.now();
  }

  String getTypeIcon() {
    switch (type) {
      case GroupType.family:
        return '👨‍👩‍👧‍👦';
      case GroupType.friends:
        return '👥';
      case GroupType.roommates:
        return '🏠';
      case GroupType.trip:
        return '✈️';
      case GroupType.project:
        return '💼';
      case GroupType.other:
        return '👥';
    }
  }

  String getTypeName() {
    switch (type) {
      case GroupType.family:
        return 'Familia';
      case GroupType.friends:
        return 'Amigos';
      case GroupType.roommates:
        return 'Roommates';
      case GroupType.trip:
        return 'Viaje';
      case GroupType.project:
        return 'Proyecto';
      case GroupType.other:
        return 'Otro';
    }
  }
}

// Modelo de Gasto Grupal
class GroupExpense {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String paidBy;  // ID del usuario que pagó
  final Map<String, double> splits;  // ID usuario -> monto que debe
  final SplitType splitType;
  final DateTime date;
  final String? description;
  final String? receiptUrl;
  final DateTime createdAt;
  final bool isSettled;

  GroupExpense({
    String? id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splits,
    required this.splitType,
    required this.date,
    this.description,
    this.receiptUrl,
    DateTime? createdAt,
    this.isSettled = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'splits': _encodeSplits(splits),
      'splitType': splitType.index,
      'date': date.toIso8601String(),
      'description': description,
      'receiptUrl': receiptUrl,
      'createdAt': createdAt.toIso8601String(),
      'isSettled': isSettled ? 1 : 0,
    };
  }

  factory GroupExpense.fromMap(Map<String, dynamic> map) {
    return GroupExpense(
      id: map['id'],
      groupId: map['groupId'],
      title: map['title'],
      amount: map['amount'],
      paidBy: map['paidBy'],
      splits: _decodeSplits(map['splits']),
      splitType: SplitType.values[map['splitType']],
      date: DateTime.parse(map['date']),
      description: map['description'],
      receiptUrl: map['receiptUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      isSettled: map['isSettled'] == 1,
    );
  }

  static String _encodeSplits(Map<String, double> splits) {
    return splits.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  static Map<String, double> _decodeSplits(String encoded) {
    Map<String, double> splits = {};
    if (encoded.isNotEmpty) {
      for (String pair in encoded.split(',')) {
        List<String> parts = pair.split(':');
        if (parts.length == 2) {
          splits[parts[0]] = double.parse(parts[1]);
        }
      }
    }
    return splits;
  }
}

// Modelo de Meta Grupal
class GroupGoal {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final Map<String, double> contributions;  // ID usuario -> monto contribuido
  final DateTime createdAt;
  final bool isCompleted;

  GroupGoal({
    String? id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    Map<String, double>? contributions,
    DateTime? createdAt,
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        contributions = contributions ?? {},
        createdAt = createdAt ?? DateTime.now();

  double get progress => targetAmount > 0 ? currentAmount / targetAmount : 0.0;
  int get daysRemaining => deadline.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'contributions': GroupExpense._encodeSplits(contributions),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory GroupGoal.fromMap(Map<String, dynamic> map) {
    return GroupGoal(
      id: map['id'],
      groupId: map['groupId'],
      title: map['title'],
      description: map['description'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'],
      deadline: DateTime.parse(map['deadline']),
      contributions: GroupExpense._decodeSplits(map['contributions']),
      createdAt: DateTime.parse(map['createdAt']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}

// Modelo de Miembro del Grupo
class GroupMember {
  final String userId;
  final String name;
  final String email;
  final double balance;  // Positivo = le deben, Negativo = debe
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.name,
    required this.email,
    this.balance = 0.0,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'balance': balance,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'],
      name: map['name'],
      email: map['email'],
      balance: map['balance'] ?? 0.0,
      joinedAt: DateTime.parse(map['joinedAt']),
    );
  }
}
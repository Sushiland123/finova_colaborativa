import 'package:uuid/uuid.dart';

// Modelo para Metas Personales
class PersonalGoal {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final DateTime createdAt;
  final String? category; // ahorro, inversión, compra, etc.
  final String? icon;
  final int color; // Color guardado como int
  bool isCompleted;

  PersonalGoal({
    String? id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.deadline,
    DateTime? createdAt,
    this.category,
    this.icon,
    this.color = 0xFF2196F3, // Azul por defecto
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get progress => targetAmount > 0 ? currentAmount / targetAmount : 0;
  double get remaining => targetAmount - currentAmount;
  int get daysRemaining => deadline.difference(DateTime.now()).inDays;
  bool get isOverdue => DateTime.now().isAfter(deadline) && !isCompleted;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'icon': icon,
      'color': color,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory PersonalGoal.fromMap(Map<String, dynamic> map) {
    return PersonalGoal(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      targetAmount: map['targetAmount']?.toDouble() ?? 0,
      currentAmount: map['currentAmount']?.toDouble() ?? 0,
      deadline: DateTime.parse(map['deadline']),
      createdAt: DateTime.parse(map['createdAt']),
      category: map['category'],
      icon: map['icon'],
      color: map['color'] ?? 0xFF2196F3,
      isCompleted: map['isCompleted'] == 1,
    );
  }

  PersonalGoal copyWith({
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? category,
    String? icon,
    int? color,
    bool? isCompleted,
  }) {
    return PersonalGoal(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// Modelo para Deudas
enum DebtType {
  personal,      // Préstamo personal
  creditCard,    // Tarjeta de crédito
  mortgage,      // Hipoteca
  student,       // Préstamo estudiantil
  car,          // Préstamo de auto
  business,      // Préstamo de negocio
  other         // Otro
}

enum PaymentFrequency {
  weekly,        // Semanal
  biweekly,      // Quincenal
  monthly,       // Mensual
  quarterly,     // Trimestral
  yearly,        // Anual
  oneTime        // Pago único
}

class Debt {
  final String id;
  final String userId;
  final String title;
  final String? creditor; // Acreedor (banco, persona, etc.)
  final double totalAmount;
  final double remainingAmount;
  final double interestRate; // Tasa de interés anual
  final DateTime startDate;
  final DateTime? dueDate;
  final DebtType type;
  final PaymentFrequency paymentFrequency;
  final double minimumPayment;
  final String? description;
  final DateTime createdAt;
  bool isPaid;

  Debt({
    String? id,
    required this.userId,
    required this.title,
    this.creditor,
    required this.totalAmount,
    required this.remainingAmount,
    this.interestRate = 0,
    required this.startDate,
    this.dueDate,
    required this.type,
    this.paymentFrequency = PaymentFrequency.monthly,
    required this.minimumPayment,
    this.description,
    DateTime? createdAt,
    this.isPaid = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get progress => totalAmount > 0 ? (totalAmount - remainingAmount) / totalAmount : 0;
  double get paidAmount => totalAmount - remainingAmount;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;
  
  // Calcular próximo pago
  DateTime? get nextPaymentDate {
    if (isPaid || dueDate == null) return null;
    
    DateTime now = DateTime.now();
    DateTime paymentDate = startDate;
    
    while (paymentDate.isBefore(now)) {
      switch (paymentFrequency) {
        case PaymentFrequency.weekly:
          paymentDate = paymentDate.add(const Duration(days: 7));
          break;
        case PaymentFrequency.biweekly:
          paymentDate = paymentDate.add(const Duration(days: 14));
          break;
        case PaymentFrequency.monthly:
          paymentDate = DateTime(paymentDate.year, paymentDate.month + 1, paymentDate.day);
          break;
        case PaymentFrequency.quarterly:
          paymentDate = DateTime(paymentDate.year, paymentDate.month + 3, paymentDate.day);
          break;
        case PaymentFrequency.yearly:
          paymentDate = DateTime(paymentDate.year + 1, paymentDate.month, paymentDate.day);
          break;
        case PaymentFrequency.oneTime:
          return dueDate;
      }
    }
    
    return paymentDate;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'creditor': creditor,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'type': type.index,
      'paymentFrequency': paymentFrequency.index,
      'minimumPayment': minimumPayment,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      creditor: map['creditor'],
      totalAmount: map['totalAmount']?.toDouble() ?? 0,
      remainingAmount: map['remainingAmount']?.toDouble() ?? 0,
      interestRate: map['interestRate']?.toDouble() ?? 0,
      startDate: DateTime.parse(map['startDate']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      type: DebtType.values[map['type']],
      paymentFrequency: PaymentFrequency.values[map['paymentFrequency']],
      minimumPayment: map['minimumPayment']?.toDouble() ?? 0,
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      isPaid: map['isPaid'] == 1,
    );
  }

  Debt copyWith({
    String? title,
    String? creditor,
    double? totalAmount,
    double? remainingAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    DebtType? type,
    PaymentFrequency? paymentFrequency,
    double? minimumPayment,
    String? description,
    bool? isPaid,
  }) {
    return Debt(
      id: id,
      userId: userId,
      title: title ?? this.title,
      creditor: creditor ?? this.creditor,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      description: description ?? this.description,
      createdAt: createdAt,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

// Extensiones de utilidad
extension DebtTypeExtension on DebtType {
  String get displayName {
    switch (this) {
      case DebtType.personal:
        return 'Préstamo Personal';
      case DebtType.creditCard:
        return 'Tarjeta de Crédito';
      case DebtType.mortgage:
        return 'Hipoteca';
      case DebtType.student:
        return 'Préstamo Estudiantil';
      case DebtType.car:
        return 'Préstamo de Auto';
      case DebtType.business:
        return 'Préstamo de Negocio';
      case DebtType.other:
        return 'Otro';
    }
  }

  String get icon {
    switch (this) {
      case DebtType.personal:
        return '👤';
      case DebtType.creditCard:
        return '💳';
      case DebtType.mortgage:
        return '🏠';
      case DebtType.student:
        return '🎓';
      case DebtType.car:
        return '🚗';
      case DebtType.business:
        return '💼';
      case DebtType.other:
        return '📄';
    }
  }
}

extension PaymentFrequencyExtension on PaymentFrequency {
  String get displayName {
    switch (this) {
      case PaymentFrequency.weekly:
        return 'Semanal';
      case PaymentFrequency.biweekly:
        return 'Quincenal';
      case PaymentFrequency.monthly:
        return 'Mensual';
      case PaymentFrequency.quarterly:
        return 'Trimestral';
      case PaymentFrequency.yearly:
        return 'Anual';
      case PaymentFrequency.oneTime:
        return 'Pago Único';
    }
  }
}
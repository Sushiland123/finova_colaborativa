/// Entidad del dominio: Transacción
/// Esta es una clase pura sin dependencias de Flutter o paquetes externos
class TransactionEntity {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final TransactionTypeEntity type;
  final TransactionCategoryEntity category;
  final DateTime date;
  final String? description;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    required this.createdAt,
  });

  /// Calcular si es ingreso o gasto
  bool get isIncome => type == TransactionTypeEntity.income;
  bool get isExpense => type == TransactionTypeEntity.expense;

  /// Copy with para inmutabilidad
  TransactionEntity copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    TransactionTypeEntity? type,
    TransactionCategoryEntity? category,
    DateTime? date,
    String? description,
    DateTime? createdAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Tipo de transacción
enum TransactionTypeEntity {
  income,
  expense,
}

/// Categorías de transacciones
enum TransactionCategoryEntity {
  // Categorías de ingreso
  salary,
  freelance,
  investment,
  gift,
  
  // Categorías de gasto
  food,
  transport,
  entertainment,
  health,
  education,
  services,
  shopping,
  others,
}

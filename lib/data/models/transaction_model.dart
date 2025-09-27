import 'package:uuid/uuid.dart';

enum TransactionType { income, expense }

enum TransactionCategory {
  // Ingresos
  salary,
  freelance,
  investment,
  gift,
  other_income,
  
  // Gastos
  food,
  transport,
  entertainment,
  health,
  education,
  shopping,
  bills,
  rent,
  other_expense,
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? description;
  final DateTime createdAt;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.index,
      'category': category.index,
      'date': date.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Crear desde Map de SQLite
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      category: TransactionCategory.values[map['category']],
      date: DateTime.parse(map['date']),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Obtener el nombre de la categoría en español
  String getCategoryName() {
    switch (category) {
      // Ingresos
      case TransactionCategory.salary:
        return 'Salario';
      case TransactionCategory.freelance:
        return 'Freelance';
      case TransactionCategory.investment:
        return 'Inversión';
      case TransactionCategory.gift:
        return 'Regalo';
      case TransactionCategory.other_income:
        return 'Otro Ingreso';
      // Gastos
      case TransactionCategory.food:
        return 'Comida';
      case TransactionCategory.transport:
        return 'Transporte';
      case TransactionCategory.entertainment:
        return 'Entretenimiento';
      case TransactionCategory.health:
        return 'Salud';
      case TransactionCategory.education:
        return 'Educación';
      case TransactionCategory.shopping:
        return 'Compras';
      case TransactionCategory.bills:
        return 'Servicios';
      case TransactionCategory.rent:
        return 'Alquiler';
      case TransactionCategory.other_expense:
        return 'Otro Gasto';
    }
  }

  // Obtener el icono de la categoría
  String getCategoryIcon() {
    switch (category) {
      case TransactionCategory.salary:
        return '💰';
      case TransactionCategory.freelance:
        return '💻';
      case TransactionCategory.investment:
        return '📈';
      case TransactionCategory.gift:
        return '🎁';
      case TransactionCategory.other_income:
        return '💵';
      case TransactionCategory.food:
        return '🍔';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.entertainment:
        return '🎮';
      case TransactionCategory.health:
        return '🏥';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.bills:
        return '📄';
      case TransactionCategory.rent:
        return '🏠';
      case TransactionCategory.other_expense:
        return '💸';
    }
  }
}
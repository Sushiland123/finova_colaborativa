import 'package:uuid/uuid.dart';

// --- EXTENSION: TransactionCategory ---
extension TransactionCategoryExtension on TransactionCategory {
  String getCategoryName() {
    switch (this) {
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

  String getCategoryIcon() {
    switch (this) {
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

  // Crear desde respuesta del backend (JSON API)
  factory Transaction.fromBackend(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      amount: _parseAmount(json['amount']),
      type: _parseType(json['type']),
      category: _parseCategory(json['category']),
      // Backend usa 'transactionDate'
      date: _parseDate(json['transactionDate'] ?? json['date']),
      description: json['description'],
      createdAt: _parseDate(json['createdAt']),
    );
  }

  // Convertir a JSON para enviar al backend
  Map<String, dynamic> toJson({bool includeId = false}) {
    final json = {
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      // Backend espera 'transactionDate' en formato yyyy-MM-dd (sin tiempo)
      'transactionDate': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };
    
    // Solo incluir campos opcionales si tienen valor
    if (description != null && description!.isNotEmpty) {
      json['description'] = description!;
    }
    
    // El ID solo se incluye en actualizaciones, no en creación
    if (includeId) {
      json['id'] = id;
    }
    
    return json;
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static TransactionType _parseType(dynamic value) {
    if (value is String) {
      return TransactionType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => TransactionType.expense,
      );
    }
    return TransactionType.expense;
  }

  static TransactionCategory _parseCategory(dynamic value) {
    if (value is String) {
      return TransactionCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => TransactionCategory.other_expense,
      );
    }
    return TransactionCategory.other_expense;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try { return DateTime.parse(value); } catch (_) {}
    }
    return DateTime.now();
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
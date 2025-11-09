import '../../domain/entities/transaction_entity.dart';
import '../models/transaction_model.dart';

/// Mapper: Convierte entre TransactionModel (data) y TransactionEntity (domain)
class TransactionMapper {
  /// Model -> Entity
  static TransactionEntity toEntity(Transaction model) {
    return TransactionEntity(
      id: model.id,
      userId: model.userId ?? '', // Manejar nullable
      title: model.title,
      amount: model.amount,
      type: _mapTypeToEntity(model.type),
      category: _mapCategoryToEntity(model.category),
      date: model.date,
      description: model.description,
      createdAt: model.createdAt,
    );
  }

  /// Entity -> Model
  static Transaction toModel(TransactionEntity entity) {
    return Transaction(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      amount: entity.amount,
      type: _mapTypeToModel(entity.type),
      category: _mapCategoryToModel(entity.category),
      date: entity.date,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }

  /// List Model -> List Entity
  static List<TransactionEntity> toEntityList(List<Transaction> models) {
    return models.map((model) => toEntity(model)).toList();
  }

  /// List Entity -> List Model
  static List<Transaction> toModelList(List<TransactionEntity> entities) {
    return entities.map((entity) => toModel(entity)).toList();
  }

  // Mappers de tipo
  static TransactionTypeEntity _mapTypeToEntity(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return TransactionTypeEntity.income;
      case TransactionType.expense:
        return TransactionTypeEntity.expense;
    }
  }

  static TransactionType _mapTypeToModel(TransactionTypeEntity type) {
    switch (type) {
      case TransactionTypeEntity.income:
        return TransactionType.income;
      case TransactionTypeEntity.expense:
        return TransactionType.expense;
    }
  }

  // Mappers de categoría
  static TransactionCategoryEntity _mapCategoryToEntity(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary:
        return TransactionCategoryEntity.salary;
      case TransactionCategory.freelance:
        return TransactionCategoryEntity.freelance;
      case TransactionCategory.investment:
        return TransactionCategoryEntity.investment;
      case TransactionCategory.gift:
        return TransactionCategoryEntity.gift;
      case TransactionCategory.food:
        return TransactionCategoryEntity.food;
      case TransactionCategory.transport:
        return TransactionCategoryEntity.transport;
      case TransactionCategory.entertainment:
        return TransactionCategoryEntity.entertainment;
      case TransactionCategory.health:
        return TransactionCategoryEntity.health;
      case TransactionCategory.education:
        return TransactionCategoryEntity.education;
      case TransactionCategory.shopping:
        return TransactionCategoryEntity.shopping;
      case TransactionCategory.bills:
        return TransactionCategoryEntity.services;
      case TransactionCategory.rent:
      case TransactionCategory.other_income:
      case TransactionCategory.other_expense:
        return TransactionCategoryEntity.others;
    }
  }

  static TransactionCategory _mapCategoryToModel(TransactionCategoryEntity category) {
    switch (category) {
      case TransactionCategoryEntity.salary:
        return TransactionCategory.salary;
      case TransactionCategoryEntity.freelance:
        return TransactionCategory.freelance;
      case TransactionCategoryEntity.investment:
        return TransactionCategory.investment;
      case TransactionCategoryEntity.gift:
        return TransactionCategory.gift;
      case TransactionCategoryEntity.food:
        return TransactionCategory.food;
      case TransactionCategoryEntity.transport:
        return TransactionCategory.transport;
      case TransactionCategoryEntity.entertainment:
        return TransactionCategory.entertainment;
      case TransactionCategoryEntity.health:
        return TransactionCategory.health;
      case TransactionCategoryEntity.education:
        return TransactionCategory.education;
      case TransactionCategoryEntity.shopping:
        return TransactionCategory.shopping;
      case TransactionCategoryEntity.services:
        return TransactionCategory.bills;
      case TransactionCategoryEntity.others:
        return TransactionCategory.other_expense;
    }
  }
}

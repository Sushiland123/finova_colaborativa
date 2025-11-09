import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/dio_provider.dart';
import '../../data/database/database_service.dart';
import '../../data/datasources/remote/transaction_remote_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/transaction_usecases.dart';
import '../../domain/usecases/auth_usecases.dart';

// ============ PROVIDERS DE DATASOURCES ============

/// Provider para DatabaseService (singleton local)
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

/// Provider para TransactionRemoteDataSource
final transactionRemoteDataSourceProvider = Provider<TransactionRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TransactionRemoteDataSource(dioClient);
});

/// Provider para AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dioClient);
});

// ============ PROVIDERS DE REPOSITORIOS ============

/// Provider para ITransactionRepository
final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  final remoteDataSource = ref.watch(transactionRemoteDataSourceProvider);
  final databaseService = ref.watch(databaseServiceProvider);
  
  return TransactionRepositoryImpl(
    remoteDataSource: remoteDataSource,
    databaseService: databaseService,
  );
});

/// Provider para IAuthRepository
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final dioClient = ref.watch(dioClientProvider);
  
  return AuthRepositoryImpl(
    remote: remoteDataSource,
    dioClient: dioClient,
  );
});

// ============ PROVIDERS DE USE CASES - TRANSACTIONS ============

final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetTransactionsUseCase(repository);
});

final createTransactionUseCaseProvider = Provider<CreateTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return CreateTransactionUseCase(repository);
});

final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return UpdateTransactionUseCase(repository);
});

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return DeleteTransactionUseCase(repository);
});

final getTransactionStatisticsUseCaseProvider = Provider<GetTransactionStatisticsUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetTransactionStatisticsUseCase(repository);
});

final getExpensesByCategoryUseCaseProvider = Provider<GetExpensesByCategoryUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetExpensesByCategoryUseCase(repository);
});

// ============ PROVIDERS DE USE CASES - AUTH ============

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final isLoggedInUseCaseProvider = Provider<IsLoggedInUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return IsLoggedInUseCase(repository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

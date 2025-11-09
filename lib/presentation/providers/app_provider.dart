import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/group_model.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/education_model.dart';
import '../../data/models/personal_finance_model.dart';
import '../../data/database/database_service.dart';
import '../../data/datasources/remote/transaction_remote_datasource.dart';
import '../../data/datasources/remote/groups_remote_datasource.dart';
import '../../core/utils/logger.dart';

class AppProvider extends ChangeNotifier {
  // Estado del usuario
  bool _isLoggedIn = false;
  bool _isFirstTime = true;
  String _userName = '';
  
  // Balance general
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  
  // Lista de transacciones
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  Map<TransactionCategory, double> _categoryExpenses = {};
  
  // Lista de grupos
  List<Group> _groups = [];
  List<GroupExpense> _currentGroupExpenses = [];
  List<GroupGoal> _currentGroupGoals = [];
  
  // Educación
  List<CourseProgress> _courseProgress = [];
  UserEducationStats? _userStats;
  
  // Metas y Deudas personales
  List<PersonalGoal> _personalGoals = [];
  List<Debt> _debts = [];
  
  // Base de datos local
  final DatabaseService _dbService = DatabaseService.instance;
  
  // Datasource remoto
  final TransactionRemoteDataSource _remoteDataSource = TransactionRemoteDataSource(DioClient());
  final GroupsRemoteDataSource _groupsRemoteDataSource = GroupsRemoteDataSource(DioClient());

  // Constructor (sin carga automática para evitar inicialización antes de auth)
  AppProvider();

  // Inicializar datos después de autenticar (se llama explícitamente)
  Future<void> initializeAfterLogin() async {
    AppLogger.info('[APP_PROVIDER] 🚀 initializeAfterLogin()');
    await loadTransactions();
    // Aquí podríamos cargar otros recursos remotos (grupos, metas, etc.) bajo demanda
  }
  
  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isFirstTime => _isFirstTime;
  String get userName => _userName;
  double get totalBalance => _totalBalance;
  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;
  List<Transaction> get transactions => _transactions;
  List<Transaction> get filteredTransactions => _filteredTransactions;
  Map<TransactionCategory, double> get categoryExpenses => _categoryExpenses;
  List<Group> get groups => _groups;
  List<GroupExpense> get currentGroupExpenses => _currentGroupExpenses;
  List<GroupGoal> get currentGroupGoals => _currentGroupGoals;
  List<CourseProgress> get courseProgress => _courseProgress;
  UserEducationStats? get userStats => _userStats;
  List<PersonalGoal> get personalGoals => _personalGoals;
  List<Debt> get debts => _debts;
  
  // Setters y métodos
  void setLoginStatus(bool status) {
    _isLoggedIn = status;
    if (status) {
      loadTransactions();
      loadPersonalGoals();
      loadDebts();
    }
    notifyListeners();
  }
  
  void setFirstTimeUser(bool status) {
    _isFirstTime = status;
    notifyListeners();
  }
  
  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }
  
  // Cargar transacciones desde backend (con fallback a local)
  Future<void> loadTransactions() async {
    try {
      AppLogger.info('[APP_PROVIDER] 🔄 Cargando transacciones desde backend...');
      // Intentar cargar desde backend primero
      _transactions = await _remoteDataSource.getTransactions();
      AppLogger.info('[APP_PROVIDER] ✅ Transacciones cargadas desde backend: ${_transactions.length}');
      
      // Actualizar estadísticas PRIMERO (antes de guardar en local)
      _filteredTransactions = _transactions;
      await updateStatistics();
      
      // Guardar en local para cache/offline (en segundo plano, sin bloquear)
      _saveToLocalAsync();
    } catch (e) {
      // Fallback a base de datos local si backend falla
      AppLogger.warning('[APP_PROVIDER] ⚠️ Error cargando desde backend, usando local: $e');
      _transactions = await _dbService.getTransactions();
      AppLogger.info('[APP_PROVIDER] 📦 Transacciones cargadas desde local: ${_transactions.length}');
      _filteredTransactions = _transactions;
      await updateStatistics();
      
      // Intentar sincronizar transacciones locales pendientes al backend
      _syncPendingTransactions();
    }
    
    notifyListeners();
  }
  
  // Guardar a local en segundo plano
  void _saveToLocalAsync() {
    // No esperamos - se ejecuta en segundo plano
    Future.microtask(() async {
      try {
        for (var transaction in _transactions) {
          await _dbService.insertTransaction(transaction);
        }
        AppLogger.info('[APP_PROVIDER] 💾 ${_transactions.length} transacciones guardadas en local');
      } catch (e) {
        AppLogger.warning('[APP_PROVIDER] ⚠️ Error guardando en local (no crítico): $e');
      }
    });
  }
  
  // Sincronizar transacciones pendientes al backend
  void _syncPendingTransactions() {
    Future.microtask(() async {
      try {
        AppLogger.info('[APP_PROVIDER] 🔄 Intentando sincronizar transacciones locales...');
        for (var transaction in _transactions) {
          try {
            // Intentar crear en backend
            await _remoteDataSource.createTransaction(transaction);
            AppLogger.info('[APP_PROVIDER] ✅ Transacción sincronizada: ${transaction.title}');
          } catch (e) {
            AppLogger.warning('[APP_PROVIDER] ⚠️ Error sincronizando ${transaction.title}: $e');
          }
        }
        // Recargar desde backend después de sincronizar
        await loadTransactions();
      } catch (e) {
        AppLogger.warning('[APP_PROVIDER] ⚠️ Error en sincronización: $e');
      }
    });
  }

  // Fuerza carga desde backend exclusivamente (para diagnóstico)
  Future<void> ensureRemoteTransactions() async {
    try {
      AppLogger.info('[APP_PROVIDER] 🔁 Forzando carga remota de transacciones...');
      _transactions = await _remoteDataSource.getTransactions();
      _filteredTransactions = _transactions;
      await updateStatistics();
      notifyListeners();
    } catch (e) {
      AppLogger.warning('[APP_PROVIDER] ❌ Error en ensureRemoteTransactions: $e');
    }
  }

  // Actualizar estadísticas basadas en las transacciones en memoria
  Future<void> updateStatistics() async {
    AppLogger.info('[APP_PROVIDER] 📊 updateStatistics() - Total transacciones: ${_transactions.length}');
    
    // Calcular estadísticas directamente desde _transactions en lugar de la BD local
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    Map<TransactionCategory, double> categoryExpenses = {};
    
    for (var transaction in _transactions) {
      AppLogger.info('[APP_PROVIDER] 📊 Procesando: ${transaction.title}, type=${transaction.type.name}, amount=${transaction.amount}');
      
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        totalExpenses += transaction.amount;
        
        // Acumular por categoría
        categoryExpenses[transaction.category] = 
            (categoryExpenses[transaction.category] ?? 0.0) + transaction.amount;
      }
    }
    
    _totalIncome = totalIncome;
    _totalExpenses = totalExpenses;
    _totalBalance = totalIncome - totalExpenses;
    _categoryExpenses = categoryExpenses;
    
    AppLogger.info('[APP_PROVIDER] 📊 Estadísticas actualizadas: Income=$totalIncome, Expenses=$totalExpenses, Balance=$_totalBalance');
    
    notifyListeners();
  }

  // Agregar nueva transacción (backend + local)
  Future<void> addTransaction(Transaction transaction) async {
    try {
      AppLogger.info('[APP_PROVIDER] 📤 Enviando transacción al backend...');
      // Enviar al backend primero
      final createdTransaction = await _remoteDataSource.createTransaction(transaction);
      AppLogger.info('[APP_PROVIDER] ✅ Transacción creada en backend con ID: ${createdTransaction.id}');
      
      // Guardar en local con el ID del backend
      await _dbService.insertTransaction(createdTransaction);
    } catch (e) {
      // Si backend falla, guardar solo local
      AppLogger.warning('[APP_PROVIDER] ⚠️ Error enviando al backend, guardando solo local: $e');
      await _dbService.insertTransaction(transaction);
    }
    
    await loadTransactions();
  }

  // Actualizar transacción (backend + local)
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      AppLogger.info('[APP_PROVIDER] 📤 Actualizando transacción en backend...');
  await _remoteDataSource.updateTransaction(transaction.id, transaction);
      AppLogger.info('[APP_PROVIDER] ✅ Transacción actualizada en backend');
      
      // Actualizar en local
      await _dbService.updateTransaction(transaction);
    } catch (e) {
      // Si backend falla, actualizar solo local
      AppLogger.warning('[APP_PROVIDER] ⚠️ Error actualizando en backend, actualizando solo local: $e');
      await _dbService.updateTransaction(transaction);
    }
    
    await loadTransactions();
  }

  // Eliminar transacción (backend + local)
  Future<void> deleteTransaction(String id) async {
    try {
      AppLogger.info('[APP_PROVIDER] 📤 Eliminando transacción del backend...');
      await _remoteDataSource.deleteTransaction(id);
      AppLogger.info('[APP_PROVIDER] ✅ Transacción eliminada del backend');
      
      // Eliminar de local
      await _dbService.deleteTransaction(id);
    } catch (e) {
      // Si backend falla, eliminar solo local
      AppLogger.warning('[APP_PROVIDER] ⚠️ Error eliminando del backend, eliminando solo local: $e');
      await _dbService.deleteTransaction(id);
    }
    
    await loadTransactions();
  }

  // Filtrar transacciones por tipo
  void filterTransactionsByType(TransactionType? type) {
    if (type == null) {
      _filteredTransactions = _transactions;
    } else {
      _filteredTransactions = _transactions.where((t) => t.type == type).toList();
    }
    notifyListeners();
  }

  // Filtrar transacciones del mes actual
  void filterCurrentMonthTransactions() {
    DateTime now = DateTime.now();
    _filteredTransactions = _transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();
    notifyListeners();
  }

  // Obtener total de gastos por categoría
  double getCategoryTotal(TransactionCategory category) {
    return _categoryExpenses[category] ?? 0.0;
  }

  // Obtener porcentaje de gasto por categoría
  double getCategoryPercentage(TransactionCategory category) {
    if (_totalExpenses == 0) return 0;
    double categoryTotal = getCategoryTotal(category);
    return (categoryTotal / _totalExpenses) * 100;
  }
  
  void resetData() {
    AppLogger.info('[APP_PROVIDER] 🧹 Limpiando datos en memoria...');
    _isLoggedIn = false;
    _userName = '';
    _totalBalance = 0.0;
    _totalIncome = 0.0;
    _totalExpenses = 0.0;
    _transactions = [];
    _filteredTransactions = [];
    _categoryExpenses = {};
    _groups = [];
    _currentGroupExpenses = [];
    _currentGroupGoals = [];
    _personalGoals = [];
    _debts = [];
    notifyListeners();
    
    // NO limpiar SQLite para mantener funcionalidad offline
    // SQLite debe estar filtrado por userId en cada consulta
  }

  // ============ MÉTODOS PARA GRUPOS ============
  
  // Cargar grupos del usuario desde el backend (con fallback a local)
  Future<void> loadGroups() async {
    try {
      AppLogger.info('[APP_PROVIDER] 🔄 Cargando grupos desde backend...');
      _groups = await _groupsRemoteDataSource.getUserGroups();
      AppLogger.info('[APP_PROVIDER] ✅ Grupos cargados desde backend: ${_groups.length}');
      
      // Guardar en local para cache/offline (en segundo plano, sin bloquear)
      _saveGroupsToLocalAsync();
    } catch (e) {
      // Fallback a base de datos local si backend falla
      AppLogger.warning('[APP_PROVIDER] ⚠️ Error cargando grupos desde backend, usando local: $e');
      String userId = _userName.isEmpty ? 'user_default' : _userName;
      _groups = await _dbService.getUserGroups(userId);
      AppLogger.info('[APP_PROVIDER] 📦 Grupos cargados desde local: ${_groups.length}');
    }
    
    notifyListeners();
  }

  // Guardar grupos a local en segundo plano
  void _saveGroupsToLocalAsync() {
    Future.microtask(() async {
      try {
        for (var group in _groups) {
          await _dbService.insertGroup(group);
        }
        AppLogger.info('[APP_PROVIDER] 💾 ${_groups.length} grupos guardados en local');
      } catch (e) {
        AppLogger.warning('[APP_PROVIDER] ⚠️ Error guardando grupos en local (no crítico): $e');
      }
    });
  }

  // Crear nuevo grupo (backend + local)
  Future<void> createGroup(String name, String description, GroupType type) async {
    try {
      AppLogger.info('[APP_PROVIDER] 📤 Creando grupo en backend...');
      
      // Crear en backend
      final createdGroup = await _groupsRemoteDataSource.createGroup(
        name: name,
        description: description,
      );
      
      AppLogger.info('[APP_PROVIDER] ✅ Grupo creado en backend con ID: ${createdGroup.id}');
      AppLogger.info('[APP_PROVIDER] 📋 Código de invitación: ${createdGroup.inviteCode}');
      
      // Guardar en local
      await _dbService.insertGroup(createdGroup);
      
      // Agregar el creador como miembro en local
      String userId = _userName.isEmpty ? 'user_default' : _userName;
      final member = GroupMember(
        userId: userId,
        name: _userName.isEmpty ? 'Usuario' : _userName,
        email: '$userId@finova.com',
      );
      await _dbService.insertGroupMember(createdGroup.id, member);
      
    } catch (e) {
      // Si backend falla, crear solo local con el tipo especificado
      AppLogger.warning('[APP_PROVIDER] ⚠️ Error creando en backend, creando solo local: $e');
      String userId = _userName.isEmpty ? 'user_default' : _userName;
      
      final group = Group(
        name: name,
        description: description,
        creatorId: userId,
        memberIds: [userId],
        type: type, // Usar el tipo especificado
      );
      
      await _dbService.insertGroup(group);
      
      // Agregar el creador como miembro
      final member = GroupMember(
        userId: userId,
        name: _userName.isEmpty ? 'Usuario' : _userName,
        email: '$userId@finova.com',
      );
      
      await _dbService.insertGroupMember(group.id, member);
    }
    
    await loadGroups();
  }

  // Unirse a grupo por código (backend + local)
  Future<bool> joinGroupByCode(String inviteCode) async {
    try {
      AppLogger.info('[APP_PROVIDER] 📤 Uniéndose a grupo con código: $inviteCode');
      
      // Unirse en backend
      final joinedGroup = await _groupsRemoteDataSource.joinGroup(inviteCode);
      
      AppLogger.info('[APP_PROVIDER] ✅ Unido al grupo: ${joinedGroup.name}');
      
      // Guardar en local
      await _dbService.insertGroup(joinedGroup);
      
      // Agregar como miembro en local
      String userId = _userName.isEmpty ? 'user_default' : _userName;
      final member = GroupMember(
        userId: userId,
        name: _userName.isEmpty ? 'Usuario' : _userName,
        email: '$userId@finova.com',
      );
      await _dbService.insertGroupMember(joinedGroup.id, member);
      
      await loadGroups();
      return true;
    } catch (e) {
      // Intentar en local como fallback
      AppLogger.warning('[APP_PROVIDER] ⚠️ Error uniéndose en backend, intentando local: $e');
      
      Group? group = await _dbService.getGroupByInviteCode(inviteCode.toUpperCase());
      
      if (group == null) {
        return false;
      }
      
      String userId = _userName.isEmpty ? 'user_default' : _userName;
      
      // Verificar si ya es miembro
      if (group.memberIds.contains(userId)) {
        return false;
      }
      
      // Agregar al usuario al grupo
      group.memberIds.add(userId);
      await _dbService.updateGroup(group);
      
      // Agregar como miembro
      final member = GroupMember(
        userId: userId,
        name: _userName.isEmpty ? 'Usuario' : _userName,
        email: '$userId@finova.com',
      );
      
      await _dbService.insertGroupMember(group.id, member);
      await loadGroups();
      
      return true;
    }
  }

  // Agregar gasto grupal (backend + local)
  Future<void> addGroupExpense(GroupExpense expense) async {
    try {
      AppLogger.info('[APP_PROVIDER] 📤 Enviando gasto grupal al backend...');
      
      // Obtener el ID del usuario actual del token (el backend usa el usuario autenticado)
      // Enviar al backend
      await _groupsRemoteDataSource.addGroupExpense(
        groupId: expense.groupId,
        title: expense.title,
        amount: expense.amount,
        paidBy: expense.paidBy,
        description: expense.description,
        splits: expense.splits,
        date: expense.date,
      );
      
      AppLogger.info('[APP_PROVIDER] ✅ Gasto grupal creado en backend');
      
      // Guardar en local
      await _dbService.insertGroupExpense(expense);
    } catch (e) {
      // Si backend falla, guardar solo local
      AppLogger.warning('[APP_PROVIDER] ⚠️ Error enviando gasto al backend, guardando solo local: $e');
      await _dbService.insertGroupExpense(expense);
    }
    
    await loadGroupExpenses(expense.groupId);
  }

  // Cargar gastos de un grupo (backend + local)
  Future<void> loadGroupExpenses(String groupId) async {
    // USAR UNA VARIABLE LOCAL en lugar de _currentGroupExpenses directamente
    List<GroupExpense> expenses = [];
    
    try {
      AppLogger.info('[APP_PROVIDER] 🔄 Cargando gastos del grupo $groupId desde backend...');
      
      // Intentar cargar desde backend primero
      expenses = await _groupsRemoteDataSource.getGroupExpenses(groupId);
      AppLogger.info('[APP_PROVIDER] ✅ Gastos cargados desde backend: ${expenses.length}');
      
      // Guardar en local para cache/offline - PASAR expenses como parámetro
      _saveGroupExpensesToLocalAsync(groupId, expenses);
    } catch (e) {
      // Fallback a base de datos local si backend falla
      AppLogger.warning('[APP_PROVIDER] ⚠️ Error cargando gastos desde backend, usando local: $e');
      expenses = await _dbService.getGroupExpenses(groupId);
      AppLogger.info('[APP_PROVIDER] 📦 Gastos cargados desde local: ${expenses.length}');
    }
    
    // Actualizar la variable de instancia DESPUÉS de cargar
    _currentGroupExpenses = expenses;
    
    // Recalcular el balance del grupo basándose en los gastos cargados
    // PASAR expenses como parámetro
    await _recalculateGroupBalance(groupId, expenses);
    
    notifyListeners();
  }
  
  // Recalcular balance del grupo basado en los gastos
  // RECIBIR expenses como parámetro en lugar de usar _currentGroupExpenses
  Future<void> _recalculateGroupBalance(String groupId, List<GroupExpense> expenses) async {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      // Calcular el balance sumando todos los montos de los gastos
      double totalBalance = 0.0;
      for (var expense in expenses) {
        totalBalance += expense.amount;
        AppLogger.info('[APP_PROVIDER] 💰 Sumando gasto: ${expense.title} = \${expense.amount}');
      }
      
      AppLogger.info('[APP_PROVIDER] 📊 Balance calculado para grupo $groupId: \$totalBalance');
      
      // Actualizar el balance del grupo
      _groups[groupIndex].totalBalance = totalBalance;
      
      // Guardar en la base de datos local
      await _dbService.updateGroup(_groups[groupIndex]);
    }
  }
  
  // Guardar gastos grupales a local en segundo plano
  // RECIBIR expenses como parámetro en lugar de usar _currentGroupExpenses
  void _saveGroupExpensesToLocalAsync(String groupId, List<GroupExpense> expenses) {
    Future.microtask(() async {
      try {
        // Limpiar gastos del grupo en local primero
        final oldExpenses = await _dbService.getGroupExpenses(groupId);
        for (var expense in oldExpenses) {
          await _dbService.deleteGroupExpense(expense.id);
        }
        
        // Guardar los nuevos gastos del backend
        for (var expense in expenses) {
          await _dbService.insertGroupExpense(expense);
        }
        AppLogger.info('[APP_PROVIDER] 💾 ${expenses.length} gastos guardados en local');
      } catch (e) {
        AppLogger.warning('[APP_PROVIDER] ⚠️ Error guardando gastos en local (no crítico): $e');
      }
    });
  }

  // Cargar metas de un grupo
  Future<void> loadGroupGoals(String groupId) async {
    _currentGroupGoals = await _dbService.getGroupGoals(groupId);
    notifyListeners();
  }

  // Agregar meta grupal
  Future<void> addGroupGoal(GroupGoal goal) async {
    await _dbService.insertGroupGoal(goal);
    await loadGroupGoals(goal.groupId);
  }

  // Calcular balance total en grupos
  double calculateGroupsBalance() {
    double totalBalance = 0.0;
    for (var group in _groups) {
      totalBalance += group.totalBalance;
    }
    return totalBalance;
  }

  // Eliminar grupo
  Future<void> deleteGroup(String groupId) async {
    await _dbService.deleteGroup(groupId);
    await loadGroups();
  }

  // Actualizar balance del grupo
  Future<void> updateGroupBalance(String groupId, double amount) async {
    // Encontrar el grupo
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      // Actualizar el balance
      _groups[groupIndex].totalBalance += amount;
      
      // Actualizar en la base de datos
      await _dbService.updateGroup(_groups[groupIndex]);
      notifyListeners();
    }
  }

  // Resetear grupo (eliminar todas las transacciones)
  Future<void> resetGroup(String groupId) async {
    // Eliminar todos los gastos del grupo
    final expenses = await _dbService.getGroupExpenses(groupId);
    for (var expense in expenses) {
      await _dbService.deleteGroupExpense(expense.id);
    }
    
    // Poner el balance en 0
    await updateGroupBalance(groupId, -_groups.firstWhere((g) => g.id == groupId).totalBalance);
    
    // Recargar gastos
    await loadGroupExpenses(groupId);
  }

  // Eliminar gasto grupal
  Future<void> deleteGroupExpense(String expenseId, String groupId, double amount) async {
    await _dbService.deleteGroupExpense(expenseId);
    // Revertir el balance
    await updateGroupBalance(groupId, -amount);
    await loadGroupExpenses(groupId);
  }

  // ============ MÉTODOS PARA EDUCACIÓN ============
  
  // Cargar progreso del usuario
  Future<void> loadEducationProgress() async {
    String userId = _userName.isEmpty ? 'user_default' : _userName;
    
    // Cargar todos los progresos
    final progressList = await _dbService.getAllUserProgress(userId);
    _courseProgress = progressList.map((map) => CourseProgress.fromMap(map)).toList();
    
    // Cargar estadísticas del usuario
    final statsMap = await _dbService.getUserStats(userId);
    if (statsMap != null) {
      _userStats = UserEducationStats.fromMap(statsMap);
    } else {
      // Crear estadísticas iniciales
      _userStats = UserEducationStats(
        userId: userId,
        totalPoints: 0,
        completedCourses: 0,
        perfectScores: 0,
      );
      await _dbService.saveUserStats(_userStats!.toMap());
    }
    
    notifyListeners();
  }
  
  // Guardar progreso de un curso
  Future<void> saveCourseProgress({
    required String courseId,
    required int score,
    required int totalQuestions,
    required List<int> userAnswers,
    required int pointsEarned,
  }) async {
    String userId = _userName.isEmpty ? 'user_default' : _userName;
    
    // Crear o actualizar progreso
    final progress = CourseProgress(
      userId: userId,
      courseId: courseId,
      isCompleted: true,
      score: score,
      totalQuestions: totalQuestions,
      pointsEarned: pointsEarned,
      completedAt: DateTime.now(),
      userAnswers: userAnswers,
    );
    
    // Guardar en BD
    await _dbService.saveCourseProgress(progress.toMap());
    
    // Actualizar estadísticas del usuario
    if (_userStats != null) {
      final newStats = UserEducationStats(
        userId: userId,
        totalPoints: _userStats!.totalPoints + pointsEarned,
        completedCourses: _userStats!.completedCourses + 1,
        perfectScores: _userStats!.perfectScores + (score == totalQuestions ? 1 : 0),
        lastActivityDate: DateTime.now(),
      );
      
      await _dbService.saveUserStats(newStats.toMap());
      _userStats = newStats;
    }
    
    // Recargar progreso
    await loadEducationProgress();
  }
  
  // Obtener progreso de un curso específico
  CourseProgress? getCourseProgress(String courseId) {
    try {
      return _courseProgress.firstWhere((p) => p.courseId == courseId);
    } catch (e) {
      return null;
    }
  }
  
  // Verificar si un curso está completado
  bool isCourseCompleted(String courseId) {
    final progress = getCourseProgress(courseId);
    return progress != null && progress.isCompleted;
  }
  
  // ============ MÉTODOS PARA METAS PERSONALES ============
  
  // Cargar metas personales
  Future<void> loadPersonalGoals() async {
    String userId = _userName.isEmpty ? 'user_default' : _userName;
    final goalMaps = await _dbService.getUserGoals(userId);
    _personalGoals = goalMaps.map((map) => PersonalGoal.fromMap(map)).toList();
    notifyListeners();
  }
  
  // Agregar nueva meta personal
  Future<void> addPersonalGoal(PersonalGoal goal) async {
    await _dbService.savePersonalGoal(goal.toMap());
    await loadPersonalGoals();
  }
  
  // Actualizar progreso de meta
  Future<void> updateGoalProgress(String goalId, double amount) async {
    final goalIndex = _personalGoals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final goal = _personalGoals[goalIndex];
      final newAmount = goal.currentAmount + amount;
      
      // Actualizar en BD
      await _dbService.updateGoalProgress(goalId, newAmount);
      
      // Si alcanzó la meta, marcarla como completada
      if (newAmount >= goal.targetAmount) {
        await _dbService.completeGoal(goalId);
      }
      
      await loadPersonalGoals();
    }
  }
  
  // Eliminar meta
  Future<void> deletePersonalGoal(String goalId) async {
    await _dbService.deletePersonalGoal(goalId);
    await loadPersonalGoals();
  }
  
  // Obtener metas activas
  List<PersonalGoal> get activeGoals => _personalGoals.where((g) => !g.isCompleted).toList();
  
  // ============ MÉTODOS PARA DEUDAS ============
  
  // Cargar deudas
  Future<void> loadDebts() async {
    String userId = _userName.isEmpty ? 'user_default' : _userName;
    final debtMaps = await _dbService.getUserDebts(userId);
    _debts = debtMaps.map((map) => Debt.fromMap(map)).toList();
    notifyListeners();
  }
  
  // Agregar nueva deuda
  Future<void> addDebt(Debt debt) async {
    await _dbService.saveDebt(debt.toMap());
    await loadDebts();
  }
  
  // Realizar pago de deuda
  Future<void> makeDebtPayment(String debtId, double paymentAmount) async {
    final debtIndex = _debts.indexWhere((d) => d.id == debtId);
    if (debtIndex != -1) {
      final debt = _debts[debtIndex];
      final newRemaining = debt.remainingAmount - paymentAmount;
      
      if (newRemaining <= 0) {
        // Deuda pagada completamente
        await _dbService.markDebtAsPaid(debtId);
      } else {
        // Actualizar monto restante
        await _dbService.updateDebtRemaining(debtId, newRemaining);
      }
      
      // Registrar el pago como transacción
      final payment = Transaction(
        title: 'Pago de ${debt.title}',
        amount: paymentAmount,
        type: TransactionType.expense,
        category: TransactionCategory.bills,
        date: DateTime.now(),
        description: 'Pago de deuda: ${debt.title}',
      );
      
      await addTransaction(payment);
      await loadDebts();
    }
  }
  
  // Eliminar deuda
  Future<void> deleteDebt(String debtId) async {
    await _dbService.deleteDebt(debtId);
    await loadDebts();
  }
  
  // Obtener deudas activas
  List<Debt> get activeDebts => _debts.where((d) => !d.isPaid).toList();
  
  // Obtener resumen de deudas
  Future<Map<String, double>> getDebtSummary() async {
    String userId = _userName.isEmpty ? 'user_default' : _userName;
    return await _dbService.getDebtSummary(userId);
  }
  
  // Calcular total de deudas activas
  double get totalActiveDebts => activeDebts.fold(0, (sum, debt) => sum + debt.remainingAmount);
}
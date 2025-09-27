import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/education_model.dart';
import '../../data/models/personal_finance_model.dart';
import '../../data/database/database_service.dart';

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
  
  // Base de datos
  final DatabaseService _dbService = DatabaseService.instance;

  // Constructor
  AppProvider() {
    loadTransactions();
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
  
  // Cargar transacciones desde la base de datos
  Future<void> loadTransactions() async {
    _transactions = await _dbService.getTransactions();
    _filteredTransactions = _transactions;
    await updateStatistics();
    notifyListeners();
  }

  // Actualizar estadísticas
  Future<void> updateStatistics() async {
    Map<String, double> stats = await _dbService.getStatistics();
    _totalIncome = stats['totalIncome']!;
    _totalExpenses = stats['totalExpenses']!;
    _totalBalance = stats['balance']!;
    
    // Cargar gastos por categoría
    _categoryExpenses = await _dbService.getExpensesByCategory();
    
    notifyListeners();
  }

  // Agregar nueva transacción
  Future<void> addTransaction(Transaction transaction) async {
    await _dbService.insertTransaction(transaction);
    await loadTransactions();
  }

  // Actualizar transacción
  Future<void> updateTransaction(Transaction transaction) async {
    await _dbService.updateTransaction(transaction);
    await loadTransactions();
  }

  // Eliminar transacción
  Future<void> deleteTransaction(String id) async {
    await _dbService.deleteTransaction(id);
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
  }

  // ============ MÉTODOS PARA GRUPOS ============
  
  // Cargar grupos del usuario
  Future<void> loadGroups() async {
    // Por ahora usamos un ID de usuario simulado
    String userId = _userName.isEmpty ? 'user_default' : _userName;
    _groups = await _dbService.getUserGroups(userId);
    notifyListeners();
  }

  // Crear nuevo grupo
  Future<void> createGroup(String name, String description, GroupType type) async {
    String userId = _userName.isEmpty ? 'user_default' : _userName;
    
    final group = Group(
      name: name,
      description: description,
      creatorId: userId,
      memberIds: [userId],
      type: type,
    );
    
    await _dbService.insertGroup(group);
    
    // Agregar el creador como miembro
    final member = GroupMember(
      userId: userId,
      name: _userName.isEmpty ? 'Usuario' : _userName,
      email: '$userId@finova.com',
    );
    
    await _dbService.insertGroupMember(group.id, member);
    await loadGroups();
  }

  // Unirse a grupo por código
  Future<bool> joinGroupByCode(String inviteCode) async {
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

  // Agregar gasto grupal
  Future<void> addGroupExpense(GroupExpense expense) async {
    await _dbService.insertGroupExpense(expense);
    await loadGroupExpenses(expense.groupId);
  }

  // Cargar gastos de un grupo
  Future<void> loadGroupExpenses(String groupId) async {
    _currentGroupExpenses = await _dbService.getGroupExpenses(groupId);
    notifyListeners();
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
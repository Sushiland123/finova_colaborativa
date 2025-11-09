import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart' as models;
import '../models/group_model.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'finova.db';
  static const int _databaseVersion = 5; // Incrementamos la versión para agregar tablas de metas y deudas

  // Tablas
  static const String tableTransactions = 'transactions';
  static const String tableGroups = 'groups';
  static const String tableGroupExpenses = 'group_expenses';
  static const String tableGroupGoals = 'group_goals';
  static const String tableGroupMembers = 'group_members';
  static const String tableCourseProgress = 'course_progress';
  static const String tableUserStats = 'user_education_stats';

  // Singleton
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  // Obtener la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Crear las tablas
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de transacciones
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        category INTEGER NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Tabla de grupos
    await db.execute('''
      CREATE TABLE $tableGroups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        creatorId TEXT NOT NULL,
        memberIds TEXT NOT NULL,
        type INTEGER NOT NULL,
        inviteCode TEXT UNIQUE,
        createdAt TEXT NOT NULL,
        imageUrl TEXT,
        totalBalance REAL DEFAULT 0.0
      )
    ''');

    // Tabla de gastos grupales
    await db.execute('''
      CREATE TABLE $tableGroupExpenses (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        paidBy TEXT NOT NULL,
        splits TEXT NOT NULL,
        splitType INTEGER NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        receiptUrl TEXT,
        createdAt TEXT NOT NULL,
        isSettled INTEGER DEFAULT 0,
        FOREIGN KEY (groupId) REFERENCES $tableGroups(id) ON DELETE CASCADE
      )
    ''');

    // Tabla de metas grupales
    await db.execute('''
      CREATE TABLE $tableGroupGoals (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        targetAmount REAL NOT NULL,
        currentAmount REAL DEFAULT 0.0,
        deadline TEXT NOT NULL,
        contributions TEXT,
        createdAt TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        FOREIGN KEY (groupId) REFERENCES $tableGroups(id) ON DELETE CASCADE
      )
    ''');

    // Tabla de miembros del grupo
    await db.execute('''
      CREATE TABLE $tableGroupMembers (
        userId TEXT NOT NULL,
        groupId TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        balance REAL DEFAULT 0.0,
        joinedAt TEXT NOT NULL,
        PRIMARY KEY (userId, groupId),
        FOREIGN KEY (groupId) REFERENCES $tableGroups(id) ON DELETE CASCADE
      )
    ''');
    
    // Tabla de progreso de cursos
    await db.execute('''
      CREATE TABLE $tableCourseProgress (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        courseId TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        score INTEGER DEFAULT 0,
        totalQuestions INTEGER DEFAULT 5,
        pointsEarned INTEGER DEFAULT 0,
        completedAt TEXT,
        startedAt TEXT NOT NULL,
        watchedSeconds INTEGER DEFAULT 0,
        userAnswers TEXT,
        UNIQUE(userId, courseId)
      )
    ''');
    
    // Tabla de estadísticas del usuario
    await db.execute('''
      CREATE TABLE $tableUserStats (
        userId TEXT PRIMARY KEY,
        totalPoints INTEGER DEFAULT 0,
        completedCourses INTEGER DEFAULT 0,
        perfectScores INTEGER DEFAULT 0,
        level INTEGER DEFAULT 0,
        lastActivityDate TEXT NOT NULL
      )
    ''');
    
    // Tabla de metas personales
    await db.execute('''
      CREATE TABLE personal_goals (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        targetAmount REAL NOT NULL,
        currentAmount REAL DEFAULT 0.0,
        icon TEXT,
        color INTEGER NOT NULL,
        deadline TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0
      )
    ''');
    
    // Tabla de deudas
    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        creditor TEXT,
        totalAmount REAL NOT NULL,
        remainingAmount REAL NOT NULL,
        minimumPayment REAL NOT NULL,
        interestRate REAL DEFAULT 0.0,
        type TEXT NOT NULL,
        paymentFrequency TEXT NOT NULL,
        nextPaymentDate TEXT,
        createdAt TEXT NOT NULL,
        isPaid INTEGER DEFAULT 0
      )
    ''');
  }

  // Actualizar la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Actualización para versión 2: tablas de grupos
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableGroups (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          creatorId TEXT NOT NULL,
          memberIds TEXT NOT NULL,
          type INTEGER NOT NULL,
          inviteCode TEXT UNIQUE,
          createdAt TEXT NOT NULL,
          imageUrl TEXT,
          totalBalance REAL DEFAULT 0.0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableGroupExpenses (
          id TEXT PRIMARY KEY,
          groupId TEXT NOT NULL,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          paidBy TEXT NOT NULL,
          splits TEXT NOT NULL,
          splitType INTEGER NOT NULL,
          date TEXT NOT NULL,
          description TEXT,
          receiptUrl TEXT,
          createdAt TEXT NOT NULL,
          isSettled INTEGER DEFAULT 0,
          FOREIGN KEY (groupId) REFERENCES $tableGroups(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableGroupGoals (
          id TEXT PRIMARY KEY,
          groupId TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          targetAmount REAL NOT NULL,
          currentAmount REAL DEFAULT 0.0,
          deadline TEXT NOT NULL,
          contributions TEXT,
          createdAt TEXT NOT NULL,
          isCompleted INTEGER DEFAULT 0,
          FOREIGN KEY (groupId) REFERENCES $tableGroups(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableGroupMembers (
          userId TEXT NOT NULL,
          groupId TEXT NOT NULL,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          balance REAL DEFAULT 0.0,
          joinedAt TEXT NOT NULL,
          PRIMARY KEY (userId, groupId),
          FOREIGN KEY (groupId) REFERENCES $tableGroups(id) ON DELETE CASCADE
        )
      ''');
    }
    
    // Actualización para versión 3 y 4: tablas de educación
    if (oldVersion < 4) {
      // Verificar si la tabla course_progress existe
      var tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableCourseProgress'"
      );
      
      if (tableExists.isEmpty) {
        // Crear tabla de progreso de cursos
        await db.execute('''
          CREATE TABLE $tableCourseProgress (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            courseId TEXT NOT NULL,
            isCompleted INTEGER DEFAULT 0,
            score INTEGER DEFAULT 0,
            totalQuestions INTEGER DEFAULT 5,
            pointsEarned INTEGER DEFAULT 0,
            completedAt TEXT,
            startedAt TEXT NOT NULL,
            watchedSeconds INTEGER DEFAULT 0,
            userAnswers TEXT,
            UNIQUE(userId, courseId)
          )
        ''');
      }
      
      // Verificar si la tabla user_education_stats existe
      tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableUserStats'"
      );
      
      if (tableExists.isEmpty) {
        // Crear tabla de estadísticas del usuario
        await db.execute('''
          CREATE TABLE $tableUserStats (
            userId TEXT PRIMARY KEY,
            totalPoints INTEGER DEFAULT 0,
            completedCourses INTEGER DEFAULT 0,
            perfectScores INTEGER DEFAULT 0,
            level INTEGER DEFAULT 0,
            lastActivityDate TEXT NOT NULL
          )
        ''');
      }
    }
    
    // Actualización para versión 5: tablas de metas personales y deudas
    if (oldVersion < 5) {
      // Crear tabla de metas personales
      await db.execute('''
        CREATE TABLE IF NOT EXISTS personal_goals (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          targetAmount REAL NOT NULL,
          currentAmount REAL DEFAULT 0.0,
          icon TEXT,
          color INTEGER NOT NULL,
          deadline TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isCompleted INTEGER DEFAULT 0
        )
      ''');
      
      // Crear tabla de deudas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debts (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          creditor TEXT,
          totalAmount REAL NOT NULL,
          remainingAmount REAL NOT NULL,
          minimumPayment REAL NOT NULL,
          interestRate REAL DEFAULT 0.0,
          type TEXT NOT NULL,
          paymentFrequency TEXT NOT NULL,
          nextPaymentDate TEXT,
          createdAt TEXT NOT NULL,
          isPaid INTEGER DEFAULT 0
        )
      ''');
    }
  }

  // ============ OPERACIONES CRUD PARA TRANSACCIONES ============

  // Crear transacción
  Future<int> insertTransaction(models.Transaction transaction) async {
    Database db = await database;
    return await db.insert(
      tableTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener todas las transacciones
  Future<List<models.Transaction>> getTransactions() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      orderBy: 'date DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromMap(maps[i]);
    });
  }

  // Obtener transacciones por tipo
  Future<List<models.Transaction>> getTransactionsByType(models.TransactionType type) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'date DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromMap(maps[i]);
    });
  }

  // Obtener transacciones del mes actual
  Future<List<models.Transaction>> getCurrentMonthTransactions() async {
    Database db = await database;
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(days: 1));

    List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      orderBy: 'date DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromMap(maps[i]);
    });
  }

  // Actualizar transacción
  Future<int> updateTransaction(models.Transaction transaction) async {
    Database db = await database;
    return await db.update(
      tableTransactions,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Eliminar todas las transacciones (útil para debug/reset)
  Future<int> deleteAllTransactions() async {
    Database db = await database;
    return await db.delete(tableTransactions);
  }

  // Eliminar transacción
  Future<int> deleteTransaction(String id) async {
    Database db = await database;
    return await db.delete(
      tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener estadísticas
  Future<Map<String, double>> getStatistics() async {
    Database db = await database;
    
    // Total ingresos
    List<Map> incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $tableTransactions WHERE type = ?',
      [models.TransactionType.income.index],
    );
    double totalIncome = incomeResult.first['total'] ?? 0.0;

    // Total gastos
    List<Map> expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $tableTransactions WHERE type = ?',
      [models.TransactionType.expense.index],
    );
    double totalExpenses = expenseResult.first['total'] ?? 0.0;

    // Balance
    double balance = totalIncome - totalExpenses;

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'balance': balance,
    };
  }

  // Obtener gastos por categoría del mes actual
  Future<Map<models.TransactionCategory, double>> getExpensesByCategory() async {
    Database db = await database;
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    
    List<Map> result = await db.rawQuery('''
      SELECT category, SUM(amount) as total 
      FROM $tableTransactions 
      WHERE type = ? AND date >= ?
      GROUP BY category
    ''', [models.TransactionType.expense.index, startOfMonth.toIso8601String()]);

    Map<models.TransactionCategory, double> categoryExpenses = {};
    
    for (var row in result) {
      categoryExpenses[models.TransactionCategory.values[row['category']]] = row['total'];
    }

    return categoryExpenses;
  }

  // ============ OPERACIONES CRUD PARA GRUPOS ============

  // Crear grupo
  Future<int> insertGroup(Group group) async {
    Database db = await database;
    return await db.insert(
      tableGroups,
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener todos los grupos del usuario
  Future<List<Group>> getUserGroups(String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableGroups,
      where: 'memberIds LIKE ?',
      whereArgs: ['%$userId%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Group.fromMap(maps[i]);
    });
  }

  // Obtener grupo por código de invitación
  Future<Group?> getGroupByInviteCode(String inviteCode) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableGroups,
      where: 'inviteCode = ?',
      whereArgs: [inviteCode],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Group.fromMap(maps.first);
    }
    return null;
  }

  // Actualizar grupo
  Future<int> updateGroup(Group group) async {
    Database db = await database;
    return await db.update(
      tableGroups,
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  // Eliminar grupo
  Future<int> deleteGroup(String id) async {
    Database db = await database;
    return await db.delete(
      tableGroups,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ OPERACIONES CRUD PARA GASTOS GRUPALES ============

  // Crear gasto grupal
  Future<int> insertGroupExpense(GroupExpense expense) async {
    Database db = await database;
    return await db.insert(
      tableGroupExpenses,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener gastos de un grupo
  Future<List<GroupExpense>> getGroupExpenses(String groupId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableGroupExpenses,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return GroupExpense.fromMap(maps[i]);
    });
  }

  // Actualizar gasto grupal
  Future<int> updateGroupExpense(GroupExpense expense) async {
    Database db = await database;
    return await db.update(
      tableGroupExpenses,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Eliminar gasto grupal
  Future<int> deleteGroupExpense(String id) async {
    Database db = await database;
    return await db.delete(
      tableGroupExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ OPERACIONES CRUD PARA METAS GRUPALES ============

  // Crear meta grupal
  Future<int> insertGroupGoal(GroupGoal goal) async {
    Database db = await database;
    return await db.insert(
      tableGroupGoals,
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener metas de un grupo
  Future<List<GroupGoal>> getGroupGoals(String groupId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableGroupGoals,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'deadline ASC',
    );

    return List.generate(maps.length, (i) {
      return GroupGoal.fromMap(maps[i]);
    });
  }

  // Actualizar meta grupal
  Future<int> updateGroupGoal(GroupGoal goal) async {
    Database db = await database;
    return await db.update(
      tableGroupGoals,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // Eliminar meta grupal
  Future<int> deleteGroupGoal(String id) async {
    Database db = await database;
    return await db.delete(
      tableGroupGoals,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ OPERACIONES PARA MIEMBROS DEL GRUPO ============

  // Agregar miembro al grupo
  Future<int> insertGroupMember(String groupId, GroupMember member) async {
    Database db = await database;
    Map<String, dynamic> data = member.toMap();
    data['groupId'] = groupId;
    return await db.insert(
      tableGroupMembers,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener miembros de un grupo
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableGroupMembers,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'joinedAt ASC',
    );

    return List.generate(maps.length, (i) {
      return GroupMember.fromMap(maps[i]);
    });
  }

  // Actualizar balance de miembro
  Future<int> updateMemberBalance(String groupId, String userId, double balance) async {
    Database db = await database;
    return await db.update(
      tableGroupMembers,
      {'balance': balance},
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, userId],
    );
  }

  // Eliminar miembro del grupo
  Future<int> deleteGroupMember(String groupId, String userId) async {
    Database db = await database;
    return await db.delete(
      tableGroupMembers,
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, userId],
    );
  }

  // ============ OPERACIONES PARA EDUCACIÓN ============

  // Guardar progreso del curso
  Future<int> saveCourseProgress(Map<String, dynamic> progress) async {
    Database db = await database;
    return await db.insert(
      tableCourseProgress,
      progress,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener progreso de un curso
  Future<Map<String, dynamic>?> getCourseProgress(String userId, String courseId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableCourseProgress,
      where: 'userId = ? AND courseId = ?',
      whereArgs: [userId, courseId],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Obtener todos los progresos del usuario
  Future<List<Map<String, dynamic>>> getAllUserProgress(String userId) async {
    Database db = await database;
    return await db.query(
      tableCourseProgress,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startedAt DESC',
    );
  }

  // Guardar o actualizar estadísticas del usuario
  Future<int> saveUserStats(Map<String, dynamic> stats) async {
    Database db = await database;
    return await db.insert(
      tableUserStats,
      stats,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener estadísticas del usuario
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableUserStats,
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // ============ OPERACIONES PARA METAS PERSONALES ============

  // Obtener metas del usuario
  Future<List<Map<String, dynamic>>> getUserGoals(String userId) async {
    Database db = await database;
    return await db.query(
      'personal_goals',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  // Guardar meta personal
  Future<int> savePersonalGoal(Map<String, dynamic> goal) async {
    Database db = await database;
    return await db.insert(
      'personal_goals',
      goal,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Actualizar progreso de meta
  Future<int> updateGoalProgress(String goalId, double newAmount) async {
    Database db = await database;
    return await db.update(
      'personal_goals',
      {'currentAmount': newAmount},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  // Marcar meta como completada
  Future<int> completeGoal(String goalId) async {
    Database db = await database;
    return await db.update(
      'personal_goals',
      {'isCompleted': 1},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  // Eliminar meta personal
  Future<int> deletePersonalGoal(String goalId) async {
    Database db = await database;
    return await db.delete(
      'personal_goals',
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  // ============ OPERACIONES PARA DEUDAS ============

  // Obtener deudas del usuario
  Future<List<Map<String, dynamic>>> getUserDebts(String userId) async {
    Database db = await database;
    return await db.query(
      'debts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  // Guardar deuda
  Future<int> saveDebt(Map<String, dynamic> debt) async {
    Database db = await database;
    return await db.insert(
      'debts',
      debt,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Actualizar monto restante de deuda
  Future<int> updateDebtRemaining(String debtId, double remaining) async {
    Database db = await database;
    return await db.update(
      'debts',
      {'remainingAmount': remaining},
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  // Marcar deuda como pagada
  Future<int> markDebtAsPaid(String debtId) async {
    Database db = await database;
    return await db.update(
      'debts',
      {'isPaid': 1, 'remainingAmount': 0},
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  // Eliminar deuda
  Future<int> deleteDebt(String debtId) async {
    Database db = await database;
    return await db.delete(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  // Obtener resumen de deudas
  Future<Map<String, double>> getDebtSummary(String userId) async {
    Database db = await database;
    
    // Obtener total de deudas
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(totalAmount) as totalDebt, SUM(remainingAmount) as remainingDebt FROM debts WHERE userId = ?',
      [userId],
    );
    
    return {
      'totalDebt': (result.first['totalDebt'] ?? 0.0) is int
          ? (result.first['totalDebt'] ?? 0.0).toDouble()
          : (result.first['totalDebt'] ?? 0.0) as double,
      'remainingDebt': (result.first['remainingDebt'] ?? 0.0) is int
          ? (result.first['remainingDebt'] ?? 0.0).toDouble()
          : (result.first['remainingDebt'] ?? 0.0) as double,
      'paidDebt': ((result.first['totalDebt'] ?? 0.0) is int
              ? (result.first['totalDebt'] ?? 0.0).toDouble()
              : (result.first['totalDebt'] ?? 0.0) as double) -
          ((result.first['remainingDebt'] ?? 0.0) is int
              ? (result.first['remainingDebt'] ?? 0.0).toDouble()
              : (result.first['remainingDebt'] ?? 0.0) as double),
    };
  }
}
// ESTE ES EL FIX PARA EL PROBLEMA DE BALANCE EN GRUPOS
// El problema era que _currentGroupExpenses se compartía entre múltiples llamadas
// a loadGroupExpenses() en paralelo, causando un race condition.

// CAMBIOS REALIZADOS:
// 1. loadGroupExpenses ahora usa una variable local 'expenses' en lugar de actualizar 
//    inmediatamente _currentGroupExpenses
// 2. _recalculateGroupBalance ahora recibe 'expenses' como parámetro
// 3. _saveGroupExpensesToLocalAsync ahora recibe 'expenses' como parámetro
// 4. _currentGroupExpenses se actualiza DESPUÉS de todos los cálculos

// Aplicar estos cambios a app_provider.dart:

/*
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
*/

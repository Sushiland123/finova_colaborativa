# Guía de Migración: home_screen.dart a Clean Architecture

## Estado Actual
- **Archivo**: `lib/presentation/screens/home_screen.dart`
- **Tamaño**: 540 líneas
- **Dependencias actuales**: 
  - `AppProvider` (Provider/ChangeNotifier) - Para transactions, groups, balances
  - `authNotifierProvider` (Riverpod) - Ya refactorizado ✅

## Cambios Necesarios

### 1. Actualizar Imports
```dart
// REMOVER:
import '../providers/app_provider.dart';

// AGREGAR:
import '../providers/transactions_provider.dart';
import '../providers/groups_provider.dart';
```

### 2. Cambiar de Provider a Riverpod Consumer

**ANTES**:
```dart
class HomeScreen extends StatefulWidget { ... }

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    return riverpod.Consumer(builder: (context, ref, _) {
      ...
    });
  }
}
```

**DESPUÉS**:
```dart
class HomeScreen extends riverpod.ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  riverpod.ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends riverpod.ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Acceder a providers mediante ref
    final transactionsState = ref.watch(transactionsNotifierProvider);
    final groupsState = ref.watch(groupsNotifierProvider);
    final themeMode = ref.watch(themeProvider);
    
    return Scaffold(...);
  }
}
```

### 3. Migrar initState

**ANTES**:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!_transactionsLoaded) {
      final provider = context.read<AppProvider>();
      await provider.loadTransactions();
      setState(() => _transactionsLoaded = true);
    }
  });
}
```

**DESPUÉS**:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!_transactionsLoaded) {
      await ref.read(transactionsNotifierProvider.notifier).loadTransactions();
      if (mounted) {
        setState(() => _transactionsLoaded = true);
      }
    }
  });
}
```

### 4. Migrar Logout Handler

**ANTES**:
```dart
// Resetear data del AppProvider
final appProvider = context.read<AppProvider>();
appProvider.resetData();

// Logout
await ref.read(authNotifierProvider.notifier).logout();
```

**DESPUÉS**:
```dart
// El resetData() ya no es necesario - los notifiers se limpian automáticamente
// Solo ejecutar logout
await ref.read(authNotifierProvider.notifier).logout();

// Opcional: Invalidar providers si es necesario
ref.invalidate(transactionsNotifierProvider);
ref.invalidate(groupsNotifierProvider);
```

### 5. Migrar Debug Actions

**ANTES**:
```dart
if (value == 'reload_groups') {
  await appProvider.loadGroups();
  ...
}
if (value == 'clear_local_transactions') {
  await dbService.deleteAllTransactions();
  await appProvider.loadTransactions();
  ...
}
```

**DESPUÉS**:
```dart
if (value == 'reload_groups') {
  await ref.read(groupsNotifierProvider.notifier).refreshGroups();
  ...
}
if (value == 'clear_local_transactions') {
  await dbService.deleteAllTransactions();
  await ref.read(transactionsNotifierProvider.notifier).loadTransactions();
  ...
}
```

### 6. Migrar Acceso a Transacciones

**ANTES**:
```dart
for (final transaction in appProvider.transactions) {
  if (transaction.type == TransactionType.income) {
    income += transaction.amount;
  } else {
    expenses += transaction.amount;
  }
}
```

**DESPUÉS**:
```dart
final transactions = transactionsState.transactions;
for (final transaction in transactions) {
  if (transaction.type == TransactionType.income) {
    income += transaction.amount;
  } else {
    expenses += transaction.amount;
  }
}
```

### 7. Actualizar Balance Calculations

**ANTES**:
```dart
Widget _buildBalanceCard(BuildContext context, AppProvider provider) {
  return Card(
    child: Text('Balance: \$${provider.totalBalance}'),
  );
}
```

**DESPUÉS**:
```dart
Widget _buildBalanceCard(BuildContext context) {
  final statistics = ref.watch(transactionsNotifierProvider).statistics;
  
  return Card(
    child: Text('Balance: \$${statistics?.totalBalance ?? 0}'),
  );
}
```

## Cambios en Métodos Auxiliares

### _calculateMonthlyData
- **Antes**: `appProvider.transactions`
- **Después**: `transactionsState.transactions`

### _buildFinancialSummary
- **Antes**: Recibe `AppProvider provider`
- **Después**: Lee directamente de `transactionsState.transactions` y `transactionsState.statistics`

### _buildBottomNavigationBar
- Sin cambios (ya no usa AppProvider)

## Testing Checklist

Después de aplicar cambios, verificar:

- [ ] ✅ Compilación sin errores
- [ ] ✅ La pantalla carga transacciones al iniciar
- [ ] ✅ El logout funciona correctamente
- [ ] ✅ Las estadísticas (balance, income, expenses) se muestran correctamente
- [ ] ✅ Los gráficos de pastel y barras muestran datos correctos
- [ ] ✅ Las debug actions funcionan (reload groups, clear transactions)
- [ ] ✅ La navegación entre pestañas funciona
- [ ] ✅ El tema claro/oscuro funciona

## Notas Importantes

1. **No es necesario `resetData()`**: Los notifiers de Riverpod se limpian automáticamente cuando se invalidan
2. **Usa `ref.invalidate()` si necesitas refrescar**: `ref.invalidate(transactionsNotifierProvider)`
3. **Acceso a loading state**: `transactionsState.isLoading`, `groupsState.isLoading`
4. **Manejo de errores**: `transactionsState.error`, `groupsState.error`
5. **Statistics**: Disponible en `transactionsState.statistics` (calculadas automáticamente)

## Siguiente Pantalla

Una vez completado home_screen.dart, migrar:
- `transactions_screen.dart` → Usar solo `transactionsNotifierProvider`
- `groups_screen.dart` → Usar solo `groupsNotifierProvider`

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../providers/theme_provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/logger.dart';
import '../../data/database/database_service.dart';
import 'transactions_screen.dart';
import 'groups_screen.dart';
import 'education_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int touchedIndex = -1;
  bool _loggingOut = false;
  bool _transactionsLoaded = false; // Flag para cargar solo una vez

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_SV',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    // Cargar transacciones al iniciar el HomeScreen
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_transactionsLoaded) {
        AppLogger.info('[HOME_SCREEN] ðŸ“¥ Cargando transacciones iniciales...');
        final provider = context.read<AppProvider>();
        await provider.loadTransactions();
        if (mounted) {
          setState(() {
            _transactionsLoaded = true;
          });
        }
        AppLogger.info('[HOME_SCREEN] âœ… Transacciones cargadas');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    return riverpod.Consumer(builder: (context, ref, _) {
      final themeMode = ref.watch(themeProvider);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Finova'),
          actions: [
            // AcciÃ³n directa para cerrar sesiÃ³n desde cualquier pestaÃ±a
            IconButton(
              icon: _loggingOut 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.logout),
              tooltip: 'Cerrar sesiÃ³n',
              onPressed: _loggingOut ? null : () async {
                try {
                  AppLogger.info('[UI] ðŸ”´ ============ AppBar Logout PRESIONADO ============');
                  
                  // Resetear data del AppProvider PRIMERO (antes de cualquier setState)
                  final appProvider = context.read<AppProvider>();
                  AppLogger.info('[UI] ðŸ”´ Reseteando data del AppProvider...');
                  appProvider.resetData();
                  
                  // AHORA sÃ­ marcamos loading (despuÃ©s de limpiar datos)
                  setState(() => _loggingOut = true);
                  
                  // Ejecutar logout
                  AppLogger.info('[UI] ðŸ”´ Llamando a authNotifier.logout()...');
                  await ref.read(authNotifierProvider.notifier).logout();
                  
                  AppLogger.info('[UI] âœ… logout() completado');
                  
                  // Mostrar mensaje de Ã©xito
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('SesiÃ³n cerrada exitosamente'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  AppLogger.error('[UI] âŒ Error al ejecutar logout (AppBar)', e);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cerrar sesiÃ³n: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setState(() => _loggingOut = false);
                  }
                }
                // No reseteamos _loggingOut aquÃ­ - dejamos que GoRouter cambie la pantalla
              },
            ),
            IconButton(
              icon: Icon(themeMode == AppThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
              tooltip: themeMode == AppThemeMode.dark ? 'Tema oscuro' : 'Tema claro',
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            ),
            if (kDebugMode)
              PopupMenuButton<String>(
                icon: const Icon(Icons.bug_report_outlined),
                tooltip: 'Debug',
                onSelected: (value) async {
                  if (value == 'invalidate') {
                    await DioClient().debugInvalidateAccessToken();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Access token invalidado (debug)')),
                      );
                    }
                  } else if (value == 'reload_groups') {
                    await appProvider.loadGroups();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Grupos recargados')),
                      );
                    }
                  } else if (value == 'clear_local_transactions') {
                    final dbService = DatabaseService.instance;
                    await dbService.deleteAllTransactions();
                    await appProvider.loadTransactions(); // Recargar desde backend
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ðŸ—‘ï¸ Transacciones locales eliminadas')),
                      );
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'invalidate', child: Text('Debug: Invalidar Access Token')),
                  PopupMenuItem(value: 'reload_groups', child: Text('Debug: Refrescar Grupos')),
                  PopupMenuItem(value: 'clear_local_transactions', child: Text('Debug: Limpiar Transacciones Locales')),
                ],
              ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildDashboard(appProvider),
              const TransactionsScreen(),
              const GroupsScreen(),
              const EducationScreen(),
              _buildProfile(appProvider, ref),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) async {
            AppLogger.info('[UI] NavigationBar tap index=$index');
            setState(() => _selectedIndex = index);
            
            // Si va a la pestaÃ±a de Grupos (index=2), cargar grupos
            // (el backend ya devuelve los balances calculados)
            if (index == 2) {
              final provider = context.read<AppProvider>();
              await provider.loadGroups();
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Movimientos'),
            NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Grupos'),
            NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Aprender'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      );
    });
  }

  Widget _buildDashboard(AppProvider appProvider) {
    // Calcular totales desde transacciones cargadas del backend
    double totalIncome = 0;
    double totalExpenses = 0;
    double balance = 0;
    
    for (final transaction in appProvider.transactions) {
      if (transaction.type.name == 'income') {
        totalIncome += transaction.amount;
      } else if (transaction.type.name == 'expense') {
        totalExpenses += transaction.amount;
      }
    }
    balance = totalIncome - totalExpenses;
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.75),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormat.format(balance),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Ingresos', totalIncome, Icons.trending_up, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryCard('Gastos', totalExpenses, Icons.trending_down, Colors.red)),
                ],
              ),
              const SizedBox(height: 24),
              _buildExpenseChart(appProvider),
              const SizedBox(height: 24),
              _buildQuickActions(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, double amount, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w600))]),
                Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 12),
            Text(_currencyFormat.format(amount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart(AppProvider appProvider) {
    // Aggregate expenses by category (assumes transactions have category.name and type)
    final expenses = <String, double>{};
    double total = 0;
    for (final t in appProvider.transactions) {
      if (t.type.name == 'expense') { // fallback if enum not imported
        expenses[t.category.name] = (expenses[t.category.name] ?? 0) + t.amount;
        total += t.amount;
      }
    }
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text('No hay gastos registrados', style: TextStyle(color: Colors.grey[600]))]),
        ),
      );
    }

    final colorMap = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Entertainment': Colors.purple,
      'Health': Colors.green,
      'Education': Colors.teal,
      'Services': Colors.red,
      'Shopping': Colors.pink,
      'Others': Colors.grey,
    };
    final labelMap = {
      'Food': 'ðŸ” AlimentaciÃ³n',
      'Transport': 'ðŸš— Transporte',
      'Entertainment': 'ðŸŽ® Entretenimiento',
      'Health': 'ðŸ¥ Salud',
      'Education': 'ðŸ“š EducaciÃ³n',
      'Services': 'ðŸ’¡ Servicios',
      'Shopping': 'ðŸ›ï¸ Compras',
      'Others': 'ðŸ“¦ Otros',
    };

    final sections = <PieChartSectionData>[];
    var i = 0;
    expenses.forEach((cat, value) {
      final percent = total == 0 ? 0 : (value / total) * 100;
      final isTouched = i == touchedIndex;
      sections.add(PieChartSectionData(
        color: colorMap[cat] ?? Colors.grey,
        value: value,
        title: isTouched ? '${percent.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 110 : 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      i++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.pie_chart, color: Theme.of(context).primaryColor), const SizedBox(width: 8), const Text('Gastos por CategorÃ­a', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions || response?.touchedSection == null) {
                        touchedIndex = -1;
                      } else {
                        touchedIndex = response!.touchedSection!.touchedSectionIndex;
                      }
                    });
                  }),
                  sectionsSpace: 1,
                  centerSpaceRadius: 0,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: expenses.entries.map((e) {
                final percent = total == 0 ? 0 : (e.value / total) * 100;
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 72) / 2,
                  child: Row(children: [
                    Container(width: 16, height: 16, decoration: BoxDecoration(color: colorMap[e.key] ?? Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(labelMap[e.key] ?? e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                        Text('${_currencyFormat.format(e.value)} (${percent.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ]),
                    )
                  ]),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acciones RÃ¡pidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _quickActionButton('Ir a Transacciones', Icons.receipt_long, Colors.blue, () => setState(() => _selectedIndex = 1))),
          const SizedBox(width: 12),
          Expanded(child: _quickActionButton('Ver Grupos', Icons.groups, Colors.green, () => setState(() => _selectedIndex = 2))),
        ])
      ],
    );
  }

  Widget _quickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)))]),
        ),
      ),
    );
  }

  Widget _buildProfile(AppProvider appProvider, riverpod.WidgetRef ref) {
    AppLogger.info('[UI] ðŸ‘¤ _buildProfile construyÃ©ndose');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          Text(appProvider.userName, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: riverpod.Consumer(
                builder: (context, debugRef, _) {
                  final authState = debugRef.watch(authNotifierProvider);
                  return FutureBuilder<List<String?>> (
                    future: Future.wait([
                      DioClient().getToken(),
                    ]),
                    builder: (context, snap) {
                      final access = snap.data?.elementAtOrNull(0);
                      return Column(
                        children: [
                          Text('Auth: ${authState.isAuthenticated ? 'LOGGED IN' : 'LOGGED OUT'}', style: const TextStyle(fontSize: 12)),
                          Text('Access(len): ${access == null ? 'null' : access.length}', style: const TextStyle(fontSize: 12)),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          _loggingOut
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    AppLogger.info('[UI] ðŸ”´ ============ BotÃ³n Cerrar SesiÃ³n PRESIONADO ============');
                    
                    try {
                      // Resetear data del AppProvider PRIMERO (antes de setState)
                      AppLogger.info('[UI] ðŸ”´ Reseteando data del AppProvider...');
                      appProvider.resetData();
                      
                      // Marca visual DESPUÃ‰S de limpiar datos
                      setState(() {
                        _loggingOut = true;
                      });

                      // Ejecutar logout
                      AppLogger.info('[UI] ðŸ”´ Llamando a authNotifier.logout()...');
                      await ref
                          .read(authNotifierProvider.notifier)
                          .logout();

                      // Verificar token realmente eliminado (debug)
                      if (kDebugMode) {
                        final tokenPost = await DioClient().getToken();
                        AppLogger.info('[UI] ðŸ” Token despuÃ©s de logout: ${tokenPost == null || tokenPost.isEmpty ? "ELIMINADO âœ…" : "AÃšN PRESENTE âš ï¸"}');
                      }
                      
                      // Mostrar mensaje de Ã©xito
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SesiÃ³n cerrada exitosamente'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      
                      AppLogger.info('[UI] âœ… Logout completado - GoRouter redirigirÃ¡ automÃ¡ticamente');
                    } catch (e) {
                      AppLogger.error('[UI] âŒ Error al ejecutar logout', e);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al cerrar sesiÃ³n: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _loggingOut = false;
                        });
                      }
                    }
                    // No reseteamos _loggingOut aquÃ­ - dejamos que GoRouter cambie la pantalla
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Cerrar SesiÃ³n'),
                )
        ],
      ),
    );
  }
}

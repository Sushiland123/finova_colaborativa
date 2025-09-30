import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import 'transactions_screen.dart';
import 'groups_screen.dart';
import 'education_screen.dart';
import '../../data/models/transaction_model.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int touchedIndex = -1;
  
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_SV',
    symbol: '\$',
    decimalDigits: 2,
  );

  // Colores para las categorías
  final Map<String, Color> categoryColors = {
    'Alimentación': Colors.orange,
    'Transporte': Colors.blue,
    'Entretenimiento': Colors.purple,
    'Salud': Colors.green,
    'Educación': Colors.teal,
    'Servicios': Colors.red,
    'Compras': Colors.pink,
    'Otros': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    return riverpod.Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeProvider);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Finova'),
            actions: [
              IconButton(
                icon: Icon(
                  themeMode == AppThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                tooltip: themeMode == AppThemeMode.dark ? 'Tema oscuro' : 'Tema claro',
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildDashboard(appProvider),
                _buildTransactions(),
                _buildGroups(),
                _buildEducation(),
                _buildProfile(appProvider),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Movimientos',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Grupos',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Aprender',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboard(AppProvider appProvider) {
    return CustomScrollView(
      slivers: [
        // Header con saludo y balance
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
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${appProvider.userName}! 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu balance actual',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(appProvider.totalBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Contenido principal
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Tarjetas de resumen
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Ingresos',
                      appProvider.totalIncome,
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Gastos',
                      appProvider.totalExpenses,
                      Icons.trending_down,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Gráfico de gastos por categoría
              _buildExpenseChart(appProvider),
              const SizedBox(height: 24),
              
              // Botones de acceso rápido
              _buildQuickActions(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormat.format(amount),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart(AppProvider appProvider) {
    // Calcular gastos por categoría
    Map<String, double> categoryExpenses = {};
    double totalExpenses = 0;
    
    for (var transaction in appProvider.transactions) {
      if (transaction.type == TransactionType.expense) {
        final categoryKey = transaction.category.name;
        categoryExpenses[categoryKey] = 
            (categoryExpenses[categoryKey] ?? 0) + transaction.amount;
        totalExpenses += transaction.amount;
      }
    }
    
    if (categoryExpenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay gastos registrados',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    
    // Preparar datos para el gráfico
    List<PieChartSectionData> sections = [];
    int index = 0;
    
    // Mapeo de categorías en inglés a español con emojis
    final Map<String, String> categoryLabels = {
      'Food': '🍔 Alimentación',
      'Transport': '🚗 Transporte',
      'Entertainment': '🎮 Entretenimiento',
      'Health': '🏥 Salud',
      'Education': '📚 Educación',
      'Services': '💡 Servicios',
      'Shopping': '🛍️ Compras',
      'Others': '📦 Otros',
    };
    
    // Mapeo de categorías a colores
    final Map<String, Color> categoryColorsMap = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Entertainment': Colors.purple,
      'Health': Colors.green,
      'Education': Colors.teal,
      'Services': Colors.red,
      'Shopping': Colors.pink,
      'Others': Colors.grey,
    };
    
    categoryExpenses.forEach((category, amount) {
      final percentage = (amount / totalExpenses) * 100;
      final isTouched = index == touchedIndex;
      
      sections.add(
        PieChartSectionData(
          color: categoryColorsMap[category] ?? Colors.grey,
          value: amount,
          title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: isTouched ? 110 : 100,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.55,
        ),
      );
      index++;
    });
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Gastos por Categoría',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Gráfico de pastel
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  startDegreeOffset: -90,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 1,
                  centerSpaceRadius: 0,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Leyenda
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: categoryExpenses.entries.map((entry) {
                final percentage = (entry.value / totalExpenses) * 100;
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 72) / 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: categoryColorsMap[entry.key] ?? Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryLabels[entry.key] ?? entry.key, // Emoji + nombre en español
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_currencyFormat.format(entry.value)} (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Ir a Transacciones',
                Icons.receipt_long,
                Colors.blue,
                () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Ver Grupos',
                Icons.groups,
                Colors.green,
                () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactions() {
    return const TransactionsScreen();
  }

  Widget _buildGroups() {
    return const GroupsScreen();
  }

  Widget _buildEducation() {
    return const EducationScreen();
  }

  Widget _buildProfile(AppProvider appProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            appProvider.userName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              appProvider.resetData();
              GoRouter.of(context).go('/login');
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

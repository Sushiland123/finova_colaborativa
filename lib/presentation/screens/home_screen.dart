import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Scaffold(
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
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart(AppProvider appProvider) {
    // Filtrar solo los gastos
    final expenses = appProvider.transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenses.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay gastos registrados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Registra tu primer gasto para ver el análisis',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calcular gastos por categoría y mostrar emoji + nombre en español
    Map<String, double> categoryExpenses = {};
    Map<String, String> categoryLabels = {};
    Map<String, Color> categoryColorsMap = {};
    for (var expense in expenses) {
      // Obtener emoji y nombre en español
      String label = '';
      String key = '';
      Color color = Colors.grey;
      try {
        label = expense.category.getCategoryIcon() + ' ' + expense.category.getCategoryName();
        key = label;
        // Mapear nombre español a color
        switch (expense.category.getCategoryName()) {
          case 'Comida': color = categoryColors['Alimentación'] ?? Colors.orange; break;
          case 'Transporte': color = categoryColors['Transporte'] ?? Colors.blue; break;
          case 'Entretenimiento': color = categoryColors['Entretenimiento'] ?? Colors.purple; break;
          case 'Salud': color = categoryColors['Salud'] ?? Colors.green; break;
          case 'Educación': color = categoryColors['Educación'] ?? Colors.teal; break;
          case 'Servicios': color = categoryColors['Servicios'] ?? Colors.red; break;
          case 'Compras': color = categoryColors['Compras'] ?? Colors.pink; break;
          case 'Otro Gasto': color = categoryColors['Otros'] ?? Colors.grey; break;
          case 'Alquiler': color = Colors.brown; break;
          default: color = Colors.grey; break;
        }
      } catch (_) {
        label = 'Otros';
        key = 'Otros';
        color = categoryColors['Otros'] ?? Colors.grey;
      }
      categoryExpenses[key] = (categoryExpenses[key] ?? 0) + expense.amount;
      categoryLabels[key] = label;
      categoryColorsMap[key] = color;
    }

    // Calcular el total
    double totalExpenses = categoryExpenses.values.fold(0, (sum, amount) => sum + amount);

    // Crear las secciones del gráfico
    List<PieChartSectionData> sections = [];
    int index = 0;
    
    categoryExpenses.forEach((category, amount) {
      final isTouched = index == touchedIndex;
      final double percentage = (amount / totalExpenses) * 100;
      final double fontSize = isTouched ? 14 : 11;
      final double radius = isTouched ? 110 : 100;
      // Usar color correcto por categoría
      sections.add(
        PieChartSectionData(
          color: categoryColorsMap[category] ?? Colors.grey,
          value: amount,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gastos por Categoría',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currencyFormat.format(totalExpenses),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
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

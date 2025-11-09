import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// 🔍 Widget de debug para visualizar el estado de sincronización
/// Agrega esto temporalmente a tu HomeScreen para diagnosticar
class SyncDebugPanel extends StatelessWidget {
  const SyncDebugPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.yellow, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.yellow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '🔍 DEBUG PANEL - SYNC STATUS',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.yellow),
              const SizedBox(height: 8),
              
              // Estado de transacciones
              _buildDebugRow(
                '📊 Transacciones en memoria',
                '${provider.transactions.length}',
                Colors.green,
              ),
              _buildDebugRow(
                '📊 Transacciones filtradas',
                '${provider.filteredTransactions.length}',
                Colors.blue,
              ),
              const SizedBox(height: 8),
              
              // Estadísticas
              _buildDebugRow(
                '💰 Total Ingresos',
                '\$${provider.totalIncome.toStringAsFixed(2)}',
                Colors.green,
              ),
              _buildDebugRow(
                '💸 Total Gastos',
                '\$${provider.totalExpenses.toStringAsFixed(2)}',
                Colors.red,
              ),
              _buildDebugRow(
                '💵 Balance',
                '\$${provider.totalBalance.toStringAsFixed(2)}',
                provider.totalBalance >= 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 8),
              
              // Categorías
              if (provider.categoryExpenses.isNotEmpty) ...[
                const Text(
                  '📂 Gastos por categoría:',
                  style: TextStyle(color: Colors.yellow, fontSize: 12),
                ),
                const SizedBox(height: 4),
                ...provider.categoryExpenses.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 2),
                    child: Text(
                      '${entry.key.name}: \$${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  );
                }),
              ],
              
              const Divider(color: Colors.yellow),
              const SizedBox(height: 8),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🔄 Recargando desde backend...')),
                      );
                      await provider.loadTransactions();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ ${provider.transactions.length} transacciones cargadas'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Recargar', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('⚠️ Confirmar'),
                          content: const Text(
                            '¿Limpiar cache local de SQLite?\n\n'
                            'Esto eliminará todas las transacciones guardadas localmente. '
                            'Las transacciones del backend no se verán afectadas.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Limpiar'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🧹 Limpiando cache local...')),
                        );
                        await provider.clearLocalCache();
                        await provider.loadTransactions();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Cache limpiado y recargado')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Limpiar Cache', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              const Text(
                'ℹ️ Este panel es solo para debug. Elimínalo en producción.',
                style: TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDebugRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔧 CÓMO USAR ESTE WIDGET:
/// 
/// 1. En tu HomeScreen o cualquier pantalla principal, agrega:
/// 
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Stack(
///       children: [
///         // Tu contenido normal
///         YourNormalContent(),
///         
///         // Panel de debug (agregar temporalmente)
///         Positioned(
///           bottom: 0,
///           left: 0,
///           right: 0,
///           child: SyncDebugPanel(),
///         ),
///       ],
///     ),
///   );
/// }
/// 
/// 2. Cuando ya no lo necesites, simplemente elimina la línea:
///    - Positioned(child: SyncDebugPanel())

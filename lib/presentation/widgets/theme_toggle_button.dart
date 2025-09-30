import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Botón animado para cambiar entre tema claro y oscuro
class ThemeToggleButton extends ConsumerWidget {
  final double size;
  final bool showLabel;

  const ThemeToggleButton({
    Key? key,
    this.size = 24.0,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    
    IconData icon;
    String label;
    Color? iconColor;
    
    // Determinar el icono y etiqueta según el modo actual
    switch (themeMode) {
      case AppThemeMode.light:
        icon = Icons.light_mode;
        label = 'Claro';
        iconColor = Colors.orange;
        break;
      case AppThemeMode.dark:
        icon = Icons.dark_mode;
        label = 'Oscuro';
        iconColor = Colors.indigo;
        break;
      case AppThemeMode.system:
        icon = Icons.auto_mode;
        label = 'Sistema';
        iconColor = null;
        break;
    }

    if (showLabel) {
      return TextButton.icon(
        onPressed: () => _showThemeDialog(context, ref),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            icon,
            key: ValueKey(icon),
            size: size,
            color: iconColor,
          ),
        ),
        label: Text(label),
      );
    }

    return IconButton(
      onPressed: () => themeNotifier.toggleTheme(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          icon,
          key: ValueKey(icon),
          size: size,
          color: iconColor,
        ),
      ),
      tooltip: 'Cambiar tema',
    );
  }

  /// Muestra un diálogo para seleccionar el modo de tema
  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context: context,
              ref: ref,
              mode: AppThemeMode.light,
              icon: Icons.light_mode,
              title: 'Tema claro',
              subtitle: 'Usar tema claro siempre',
              color: Colors.orange,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              mode: AppThemeMode.dark,
              icon: Icons.dark_mode,
              title: 'Tema oscuro',
              subtitle: 'Usar tema oscuro siempre',
              color: Colors.indigo,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              mode: AppThemeMode.system,
              icon: Icons.auto_mode,
              title: 'Automático',
              subtitle: 'Seguir configuración del sistema',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required AppThemeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    final currentMode = ref.watch(themeProvider);
    final isSelected = currentMode == mode;
    
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
        Navigator.of(context).pop();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
    );
  }
}

/// Widget de configuración de tema más elaborado para la página de ajustes
class ThemeSettingsTile extends ConsumerWidget {
  const ThemeSettingsTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tema de la aplicación',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(
                  value: AppThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Oscuro'),
                ),
                ButtonSegment(
                  value: AppThemeMode.system,
                  icon: Icon(Icons.auto_mode),
                  label: Text('Auto'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (Set<AppThemeMode> newSelection) {
                ref.read(themeProvider.notifier).setTheme(newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}

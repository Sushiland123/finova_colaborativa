import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

/// Enumeración para los modos de tema
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Provider Notifier para gestionar el estado del tema
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';

  ThemeNotifier(this._prefs) : super(AppThemeMode.system) {
    _loadTheme();
  }

  /// Carga el tema guardado en SharedPreferences
  void _loadTheme() {
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      state = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => AppThemeMode.system,
      );
    }
  }

  /// Cambia el tema y lo guarda en SharedPreferences
  void setTheme(AppThemeMode mode) {
    state = mode;
    _prefs.setString(_themeKey, mode.toString());
  }

  /// Alterna entre tema claro y oscuro
  void toggleTheme() {
    switch (state) {
      case AppThemeMode.light:
        setTheme(AppThemeMode.dark);
        break;
      case AppThemeMode.dark:
        setTheme(AppThemeMode.light);
        break;
      case AppThemeMode.system:
        // Si está en sistema, determinar el tema actual y cambiar al opuesto
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        setTheme(brightness == Brightness.dark ? AppThemeMode.light : AppThemeMode.dark);
        break;
    }
  }

  /// Obtiene el ThemeMode actual para MaterialApp
  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Verifica si el tema actual es oscuro
  bool get isDarkMode {
    switch (state) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark;
    }
  }
}

/// Provider principal para el tema
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

/// Provider para obtener el ThemeMode directamente
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appThemeMode = ref.watch(themeProvider);
  switch (appThemeMode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});

/// Provider para verificar si el tema es oscuro
final isDarkModeProvider = Provider<bool>((ref) {
  final themeNotifier = ref.watch(themeProvider.notifier);
  return themeNotifier.isDarkMode;
});

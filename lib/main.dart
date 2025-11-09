// Rutas centralizadas con guard de autenticación
import 'routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones de la app
import 'presentation/providers/app_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientación (solo vertical)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FinovaApp(),
    ),
  );
}

class FinovaApp extends ConsumerStatefulWidget {
  const FinovaApp({Key? key}) : super(key: key);

  @override
  ConsumerState<FinovaApp> createState() => _FinovaAppState();
}

class _FinovaAppState extends ConsumerState<FinovaApp> {
  late AppProvider _appProvider;

  @override
  void initState() {
    super.initState();
    // Inicializar AppProvider
    _appProvider = AppProvider();
    
    // Verificar sesión al iniciar la app
    print('[MAIN] 🚀 ============ FINOVA APP initState ============');
    Future.microtask(() async {
      print('[MAIN] 🚀 Llamando a checkSession()...');
      // Pasar appProvider al checkSession para que pueda cargar datos
      final authNotifier = ref.read(authNotifierProvider.notifier);
      // Como AuthNotifier ya está creado, vamos a usar un approach diferente
      await authNotifier.checkSession();
      
      // Si está autenticado, cargar transacciones
      if (ref.read(authNotifierProvider).isAuthenticated) {
        print('[MAIN] 📥 Usuario autenticado, cargando transacciones iniciales...');
        await _appProvider.loadTransactions();
        print('[MAIN] ✅ Transacciones iniciales cargadas');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Observar el tema desde Riverpod
    final themeMode = ref.watch(themeModeProvider);
    
  final router = ref.watch(goRouterProvider);

  return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider.value(value: _appProvider),
        // Agregar más providers de Provider aquí según necesites
      ],
      child: MaterialApp.router(
        title: 'Finova Colaborativa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode, // Usar el tema desde Riverpod
  routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'SV'),
          Locale('es'),
        ],
      ),
    );
  }
}
// Las rutas ahora se administran en `routes/app_router.dart`

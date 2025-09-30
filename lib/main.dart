import 'data/models/group_model.dart';
import 'data/models/education_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones de la app
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/groups_screen.dart';
import 'presentation/screens/group_detail_screen.dart';
import 'presentation/screens/education_screen.dart';
import 'presentation/screens/course_detail.dart';
import 'presentation/screens/transactions_screen.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';

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

class FinovaApp extends ConsumerWidget {
  const FinovaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar el tema desde Riverpod
    final themeMode = ref.watch(themeModeProvider);
    
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => AppProvider()),
        // Agregar más providers de Provider aquí según necesites
      ],
      child: MaterialApp.router(
        title: 'Finova Colaborativa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode, // Usar el tema desde Riverpod
        routerConfig: _router,
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

// Configuración de rutas
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/groups',
      builder: (context, state) => const GroupsScreen(),
    ),
    GoRoute(
      path: '/group-detail',
      builder: (context, state) {
        final group = state.extra;
        if (group == null || group is! Group) {
          return const Scaffold(body: Center(child: Text('Grupo no especificado')));
        }
  return GroupDetailScreen(group: group);
      },
    ),
    GoRoute(
      path: '/education',
      builder: (context, state) => const EducationScreen(),
    ),
    GoRoute(
      path: '/course-detail',
      builder: (context, state) {
        final course = state.extra;
        if (course == null || course is! Course) {
          return const Scaffold(body: Center(child: Text('Curso no especificado')));
        }
  return CourseDetailScreen(course: course);
      },
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionsScreen(),
    ),
  ],
);

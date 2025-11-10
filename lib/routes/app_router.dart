import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/providers/auth_provider.dart';

// Pantallas
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/onboarding_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/groups_screen.dart';
import '../presentation/screens/group_detail_screen.dart';
import '../presentation/screens/education_screen.dart';
import '../presentation/screens/course_detail.dart';
import '../presentation/screens/transactions_screen.dart';

// Modelos usados en rutas con extra
import '../data/models/group_model.dart';
import '../data/models/education_model.dart';

/// Proveedor de GoRouter que reacciona al estado de autenticación.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final isAuthenticated = authState.isAuthenticated;
  final isLoading = authState.isLoading;

  print('[ROUTER] 🔄 ================ PROVIDER REBUILD ================');
  print('[ROUTER] 🔄 Estado: isAuth=$isAuthenticated, isLoading=$isLoading, userId=${authState.userId}');
  print('[ROUTER] 🔄 ================================================');

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation; // Ubicación solicitada
      final loggingIn = loc == '/login';
      final registering = loc == '/register';
      final onboarding = loc == '/onboarding';
      final splash = loc == '/splash';
      final isPublicRoute = loggingIn || registering || onboarding || splash;

      print('[ROUTER] 🚦 ================ REDIRECT ================');
      print('[ROUTER] 🚦 Ubicación: $loc');
      print('[ROUTER] 🚦 isAuth=$isAuthenticated, isLoading=$isLoading');

      // Si NO está autenticado, redirigir a login (excepto si ya está en ruta pública)
      if (!isAuthenticated) {
        if (!isPublicRoute) {
          print('[ROUTER] ➡️ No autenticado → redirigiendo a /login');
          return '/login';
        }
        print('[ROUTER] ✓ No autenticado en ruta pública ($loc)');
        return null;
      }

      // Si está autenticado, evitar pantallas públicas
      if (isPublicRoute) {
        print('[ROUTER] ➡️ Autenticado en ruta pública → redirigiendo a /home');
        return '/home';
      }

      print('[ROUTER] ✓ Autenticado en ruta protegida ($loc)');
      return null;
    },
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
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
            return const Scaffold(
              body: Center(child: Text('Grupo no especificado')),
            );
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
            return const Scaffold(
              body: Center(child: Text('Curso no especificado')),
            );
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
});

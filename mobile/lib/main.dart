import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/vehicle_detail/screens/vehicle_detail_screen.dart';

void main() {
  runApp(const ProviderScope(child: AutoDocApp()));
}

class AutoDocApp extends ConsumerWidget {
  const AutoDocApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final router = GoRouter(
      initialLocation: authState.isAuthenticated ? '/' : '/login',
      redirect: (context, state) {
        final loggedIn = authState.isAuthenticated;
        final goingToLogin = state.matchedLocation == '/login';
        if (!loggedIn && !goingToLogin) return '/login';
        if (loggedIn && goingToLogin) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
        GoRoute(
          path: '/vehicle/:id',
          builder: (_, state) =>
              VehicleDetailScreen(vehicleId: state.pathParameters['id']!),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'AutoDoc Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/vehicle_detail/screens/vehicle_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supportDir = await getApplicationSupportDirectory();
  final cookieJar = PersistCookieJar(
    storage: FileStorage('${supportDir.path}/cookies'),
  );

  runApp(
    ProviderScope(
      overrides: [cookieJarProvider.overrideWithValue(cookieJar)],
      child: const AutoDocApp(),
    ),
  );
}

class AutoDocApp extends ConsumerWidget {
  const AutoDocApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AutoDoc Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<AuthState>(ref.read(authProvider));
  ref
    ..listen<AuthState>(
      authProvider,
      (_, next) => refreshListenable.value = next,
    )
    ..onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loggedIn = authState.isAuthenticated;
      final goingToLogin = state.matchedLocation == '/login';
      final goingToSplash = state.matchedLocation == '/splash';

      if (authState.isInitializing) {
        return goingToSplash ? null : '/splash';
      }
      if (!loggedIn) {
        return goingToLogin ? null : '/login';
      }
      if (goingToLogin || goingToSplash) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
      GoRoute(
        path: '/vehicle/:id',
        builder: (_, state) =>
            VehicleDetailScreen(vehicleId: state.pathParameters['id']!),
      ),
    ],
  );
});

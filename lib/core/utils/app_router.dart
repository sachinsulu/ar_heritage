// lib/core/utils/app_router.dart

import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/monument_detail/presentation/screens/monument_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (_, __) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/monument/:id',
      builder: (_, state) => MonumentDetailScreen(
        monumentId: state.pathParameters['id'] ?? '',
      ),
    ),
  ],
);

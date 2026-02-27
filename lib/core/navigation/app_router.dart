import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/screens/alerts_feed_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/map/presentation/screens/situational_map_screen.dart';
import '../../features/reports/presentation/screens/report_incident_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Temporarily disable auth-based redirects so the
  // dashboard is always accessible for demo.
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/map',
        builder: (context, state) => const SituationalMapScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportIncidentScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsFeedScreen(),
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (context, state) {
          return TrackingScreen(reportId: state.pathParameters['id']!);
        },
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

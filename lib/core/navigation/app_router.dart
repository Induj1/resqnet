import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/screens/alerts_feed_screen.dart';
import '../../features/assistant/presentation/screens/crisis_assistant_screen.dart';
import '../../features/assistant/presentation/screens/panic_assistant_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/event_detail_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/map/presentation/screens/situational_map_screen.dart';
import '../../features/reports/presentation/screens/quick_report_screen.dart';
import '../../features/reports/presentation/screens/report_incident_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/map', builder: (context, state) => const SituationalMapScreen()),
      GoRoute(path: '/report', builder: (context, state) => const QuickReportScreen()),
      GoRoute(path: '/report-form', builder: (context, state) => const ReportIncidentScreen()),
      GoRoute(path: '/alerts', builder: (context, state) => const AlertsFeedScreen()),
      GoRoute(
        path: '/tracking/:id',
        builder: (context, state) => TrackingScreen(reportId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/assistant',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'type';
          return PanicAssistantScreen(mode: mode);
        },
      ),
      GoRoute(path: '/assistant-lab', builder: (context, state) => const CrisisAssistantScreen()),
      GoRoute(path: '/community', builder: (context, state) => const CommunityScreen()),
      GoRoute(
        path: '/community/event/:id',
        builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
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


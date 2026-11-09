import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
    ],
  );
}

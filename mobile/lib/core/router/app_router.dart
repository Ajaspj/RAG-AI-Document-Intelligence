import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/chat_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/documents/presentation/documents_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../shared/widgets/main_scaffold_wrapper.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorHome = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  static final _shellNavigatorDocuments = GlobalKey<NavigatorState>(debugLabel: 'shellDocuments');
  static final _shellNavigatorChat = GlobalKey<NavigatorState>(debugLabel: 'shellChat');
  static final _shellNavigatorProfile = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffoldWrapper(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home / Dashboard
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHome,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),

          // Branch 2: Documents
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDocuments,
            routes: [
              GoRoute(
                path: '/documents',
                builder: (context, state) => const DocumentsPage(),
              ),
            ],
          ),

          // Branch 3: AI Chat
          StatefulShellBranch(
            navigatorKey: _shellNavigatorChat,
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatPage(),
              ),
            ],
          ),

          // Branch 4: Profile & Settings
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfile,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

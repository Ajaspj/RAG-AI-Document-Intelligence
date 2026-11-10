import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/documents/presentation/documents_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../shared/widgets/main_scaffold_wrapper.dart';
import '../storage/secure_storage_service.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorHome = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  static final _shellNavigatorDocuments = GlobalKey<NavigatorState>(debugLabel: 'shellDocuments');
  static final _shellNavigatorChat = GlobalKey<NavigatorState>(debugLabel: 'shellChat');
  static final _shellNavigatorProfile = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  static GoRouter createRouter({
    required AuthBloc authBloc,
    required SecureStorageService storageService,
  }) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final location = state.matchedLocation;

        final isSplash = location == '/splash';
        final isAuthRoute = location == '/sign-in' ||
            location == '/sign-up' ||
            location == '/onboarding' ||
            location == '/forgot-password';

        // Allow splash to run on startup
        if (authState is AuthInitial || (authState is AuthLoading && isSplash)) {
          return null;
        }

        final isAuthenticated = authState is AuthAuthenticated;

        if (!isAuthenticated) {
          // If on splash, transition to appropriate entry point
          if (isSplash) {
            final unauth = authState is AuthUnauthenticated ? authState : null;
            return (unauth?.hasSeenOnboarding ?? false) ? '/sign-in' : '/onboarding';
          }

          // If on auth routes, stay there
          if (isAuthRoute) {
            return null;
          }

          // Any protected route without auth redirects to /sign-in
          return '/sign-in';
        }

        // If authenticated, do not allow staying on auth/splash pages
        if (isSplash || isAuthRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => OnboardingPage(storageService: storageService),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: '/sign-up',
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
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
}

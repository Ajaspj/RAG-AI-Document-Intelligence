import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/forgot_password.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:mobile/features/auth/domain/usecases/sign_in.dart';
import 'package:mobile/features/auth/domain/usecases/sign_out.dart';
import 'package:mobile/features/auth/domain/usecases/sign_up.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/main.dart';

class TestSecureStorageService extends SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveAccessToken(String token) async => _data['access_token'] = token;

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<void> saveRefreshToken(String token) async => _data['refresh_token'] = token;

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> saveUserData(String userData) async => _data['user_data'] = userData;

  @override
  Future<String?> getUserData() async => _data['user_data'];

  @override
  Future<void> setHasSeenOnboarding(bool hasSeen) async =>
      _data['has_seen_onboarding'] = hasSeen.toString();

  @override
  Future<bool> hasSeenOnboarding() async => _data['has_seen_onboarding'] == 'true';

  @override
  Future<void> clearTokens() async {
    _data.remove('access_token');
    _data.remove('refresh_token');
  }

  @override
  Future<void> clearSession() async {
    _data.remove('access_token');
    _data.remove('refresh_token');
    _data.remove('user_data');
  }
}

class TestAuthRepository implements AuthRepository {
  User? userToRestore;

  final testUser = User(
    id: 'user-001',
    email: 'alex@documind.ai',
    fullName: 'Alex Vance',
    isActive: true,
    createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
  );

  @override
  Future<User> signIn(String email, String password) async => testUser;

  @override
  Future<User> signUp(String fullName, String email, String password) async => testUser;

  @override
  Future<void> signOut() async {
    userToRestore = null;
  }

  @override
  Future<User?> restoreSession() async => userToRestore;

  @override
  Future<String> forgotPassword(String email) async => 'Reset email sent';
}

void main() {
  testWidgets('Fresh unauthenticated user navigates to onboarding and sign-in',
      (WidgetTester tester) async {
    final storageService = TestSecureStorageService();
    final authRepository = TestAuthRepository();
    authRepository.userToRestore = null; // No session

    final authBloc = AuthBloc(
      restoreSessionUseCase: RestoreSessionUseCase(authRepository),
      signInUseCase: SignInUseCase(authRepository),
      signUpUseCase: SignUpUseCase(authRepository),
      signOutUseCase: SignOutUseCase(authRepository),
      forgotPasswordUseCase: ForgotPasswordUseCase(authRepository),
      storageService: storageService,
    );

    final router = AppRouter.createRouter(
      authBloc: authBloc,
      storageService: storageService,
    );

    await tester.pumpWidget(
      DocumentIntelligenceApp(
        authBloc: authBloc,
        storageService: storageService,
        router: router,
      ),
    );

    // Initial splash frame
    expect(find.text('DocuMind AI'), findsOneWidget);

    // Settle async auth check & navigation redirect to Onboarding
    await tester.pumpAndSettle();

    // Verify Onboarding Page is displayed
    expect(find.text('Intelligent Documents.\nGrounded Answers.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Tap "Sign In" button on onboarding page
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify Sign In Page is displayed
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    authBloc.close();
  });

  testWidgets('Authenticated user restores session and navigates all tabs',
      (WidgetTester tester) async {
    final storageService = TestSecureStorageService();
    final authRepository = TestAuthRepository();
    // Pre-populate session
    authRepository.userToRestore = authRepository.testUser;

    final authBloc = AuthBloc(
      restoreSessionUseCase: RestoreSessionUseCase(authRepository),
      signInUseCase: SignInUseCase(authRepository),
      signUpUseCase: SignUpUseCase(authRepository),
      signOutUseCase: SignOutUseCase(authRepository),
      forgotPasswordUseCase: ForgotPasswordUseCase(authRepository),
      storageService: storageService,
    );

    final router = AppRouter.createRouter(
      authBloc: authBloc,
      storageService: storageService,
    );

    await tester.pumpWidget(
      DocumentIntelligenceApp(
        authBloc: authBloc,
        storageService: storageService,
        router: router,
      ),
    );

    // Settle frames: Splash -> Restores session -> Redirects to Dashboard (/)
    await tester.pumpAndSettle();

    // Verify Dashboard is displayed with brand and greeting
    expect(find.text('DocuMind AI'), findsOneWidget);
    expect(find.text('Good to see you 👋'), findsOneWidget);

    // Verify Overview Stat Cards
    expect(find.text('Total Files'), findsOneWidget);
    expect(find.text('Processed'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('AI Queries'), findsOneWidget);

    // Test Navigation: Tap "Documents" tab
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('My Documents'), findsOneWidget);

    // Test Navigation: Tap "AI Chat" tab
    await tester.tap(find.text('AI Chat'));
    await tester.pumpAndSettle();
    expect(find.text('DocuMind Assistant'), findsOneWidget);

    // Test Navigation: Tap "Profile" tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Account & Settings'), findsOneWidget);
    // Verify authenticated user details are displayed
    expect(find.text('Alex Vance'), findsOneWidget);
    expect(find.text('alex@documind.ai'), findsOneWidget);

    // Scroll to Sign Out button
    await tester.scrollUntilVisible(find.text('Sign Out'), 100);
    expect(find.text('Sign Out'), findsOneWidget);

    // Return to Home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Good to see you 👋'), findsOneWidget);

    authBloc.close();
  });
}

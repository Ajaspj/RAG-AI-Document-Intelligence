import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failure.dart' hide AuthFailure;
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/forgot_password.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:mobile/features/auth/domain/usecases/sign_in.dart';
import 'package:mobile/features/auth/domain/usecases/sign_out.dart';
import 'package:mobile/features/auth/domain/usecases/sign_up.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> saveAccessToken(String token) async => _storage['access_token'] = token;

  @override
  Future<String?> getAccessToken() async => _storage['access_token'];

  @override
  Future<void> saveRefreshToken(String token) async => _storage['refresh_token'] = token;

  @override
  Future<String?> getRefreshToken() async => _storage['refresh_token'];

  @override
  Future<void> saveUserData(String userData) async => _storage['user_data'] = userData;

  @override
  Future<String?> getUserData() async => _storage['user_data'];

  @override
  Future<void> setHasSeenOnboarding(bool hasSeen) async =>
      _storage['has_seen_onboarding'] = hasSeen.toString();

  @override
  Future<bool> hasSeenOnboarding() async => _storage['has_seen_onboarding'] == 'true';

  @override
  Future<void> clearTokens() async {
    _storage.remove('access_token');
    _storage.remove('refresh_token');
  }

  @override
  Future<void> clearSession() async {
    _storage.remove('access_token');
    _storage.remove('refresh_token');
    _storage.remove('user_data');
  }
}

class FakeAuthRepository implements AuthRepository {
  User? userToRestore;
  Failure? failureToThrow;
  bool shouldThrowGeneric = false;

  final testUser = User(
    id: 'user-123',
    email: 'test@documind.ai',
    fullName: 'Test User',
    isActive: true,
    createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
  );

  @override
  Future<User> signIn(String email, String password) async {
    if (failureToThrow != null) throw failureToThrow!;
    if (shouldThrowGeneric) throw Exception('Network error');
    return testUser;
  }

  @override
  Future<User> signUp(String fullName, String email, String password) async {
    if (failureToThrow != null) throw failureToThrow!;
    if (shouldThrowGeneric) throw Exception('Network error');
    return testUser;
  }

  @override
  Future<void> signOut() async {
    userToRestore = null;
  }

  @override
  Future<User?> restoreSession() async {
    if (failureToThrow != null) throw failureToThrow!;
    return userToRestore;
  }

  @override
  Future<String> forgotPassword(String email) async {
    if (failureToThrow != null) throw failureToThrow!;
    if (shouldThrowGeneric) throw Exception('Network error');
    return 'Password reset instructions sent if email exists';
  }
}

void main() {
  late FakeAuthRepository authRepository;
  late FakeSecureStorageService storageService;
  late AuthBloc authBloc;

  setUp(() {
    authRepository = FakeAuthRepository();
    storageService = FakeSecureStorageService();
    authBloc = AuthBloc(
      restoreSessionUseCase: RestoreSessionUseCase(authRepository),
      signInUseCase: SignInUseCase(authRepository),
      signUpUseCase: SignUpUseCase(authRepository),
      signOutUseCase: SignOutUseCase(authRepository),
      forgotPasswordUseCase: ForgotPasswordUseCase(authRepository),
      storageService: storageService,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state should be AuthInitial', () {
    expect(authBloc.state, equals(const AuthInitial()));
  });

  group('AuthCheckRequested', () {
    test('emits [AuthLoading, AuthAuthenticated] when session restoration succeeds', () async {
      authRepository.userToRestore = authRepository.testUser;

      final expectedStates = [
        const AuthLoading(),
        AuthAuthenticated(authRepository.testUser),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthCheckRequested());
    });

    test('emits [AuthLoading, AuthUnauthenticated(hasSeenOnboarding: false)] when no session and onboarding not seen', () async {
      authRepository.userToRestore = null;

      final expectedStates = [
        const AuthLoading(),
        const AuthUnauthenticated(hasSeenOnboarding: false),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthCheckRequested());
    });

    test('emits [AuthLoading, AuthUnauthenticated(hasSeenOnboarding: true)] when no session and onboarding seen', () async {
      authRepository.userToRestore = null;
      await storageService.setHasSeenOnboarding(true);

      final expectedStates = [
        const AuthLoading(),
        const AuthUnauthenticated(hasSeenOnboarding: true),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthCheckRequested());
    });
  });

  group('SignInRequested', () {
    test('emits [AuthLoading, AuthAuthenticated] on successful sign in', () async {
      final expectedStates = [
        const AuthLoading(),
        AuthAuthenticated(authRepository.testUser),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const SignInRequested(
        email: 'test@documind.ai',
        password: 'Password123!',
      ));
    });

    test('emits [AuthLoading, AuthFailure] when sign in fails with Failure', () async {
      authRepository.failureToThrow = const ServerFailure('Invalid email or password', 401);

      final expectedStates = [
        const AuthLoading(),
        const AuthFailure('Invalid email or password'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const SignInRequested(
        email: 'wrong@documind.ai',
        password: 'wrongpassword',
      ));
    });
  });

  group('SignUpRequested', () {
    test('emits [AuthLoading, AuthAuthenticated] on successful sign up', () async {
      final expectedStates = [
        const AuthLoading(),
        AuthAuthenticated(authRepository.testUser),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const SignUpRequested(
        fullName: 'Test User',
        email: 'test@documind.ai',
        password: 'Password123!',
      ));
    });

    test('emits [AuthLoading, AuthFailure] on sign up error', () async {
      authRepository.failureToThrow = const ServerFailure('An account with this email already exists', 409);

      final expectedStates = [
        const AuthLoading(),
        const AuthFailure('An account with this email already exists'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const SignUpRequested(
        fullName: 'Test User',
        email: 'exists@documind.ai',
        password: 'Password123!',
      ));
    });
  });

  group('SignOutRequested', () {
    test('emits [AuthLoading, AuthUnauthenticated] on sign out', () async {
      await storageService.setHasSeenOnboarding(true);

      final expectedStates = [
        const AuthLoading(),
        const AuthUnauthenticated(hasSeenOnboarding: true),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const SignOutRequested());
    });
  });

  group('ForgotPasswordRequested', () {
    test('emits [AuthLoading, PasswordResetSuccess] on valid request', () async {
      final expectedStates = [
        const AuthLoading(),
        const PasswordResetSuccess('Password reset instructions sent if email exists'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const ForgotPasswordRequested('test@documind.ai'));
    });

    test('emits [AuthLoading, AuthFailure] on failure', () async {
      authRepository.failureToThrow = const ServerFailure('Rate limit exceeded', 429);

      final expectedStates = [
        const AuthLoading(),
        const AuthFailure('Rate limit exceeded'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const ForgotPasswordRequested('test@documind.ai'));
    });
  });
}

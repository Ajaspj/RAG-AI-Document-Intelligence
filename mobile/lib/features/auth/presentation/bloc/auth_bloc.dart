import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart' hide AuthFailure;
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/restore_session.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RestoreSessionUseCase restoreSessionUseCase;
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final SecureStorageService storageService;

  AuthBloc({
    required this.restoreSessionUseCase,
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.forgotPasswordUseCase,
    required this.storageService,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await restoreSessionUseCase();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        final hasSeenOnboarding = await storageService.hasSeenOnboarding();
        emit(AuthUnauthenticated(hasSeenOnboarding: hasSeenOnboarding));
      }
    } catch (_) {
      final hasSeenOnboarding = await storageService.hasSeenOnboarding();
      emit(AuthUnauthenticated(hasSeenOnboarding: hasSeenOnboarding));
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());

    try {
      final user = await signInUseCase(event.email, event.password);
      emit(AuthAuthenticated(user));
    } on Failure catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());

    try {
      final user = await signUpUseCase(
        event.fullName,
        event.email,
        event.password,
      );
      emit(AuthAuthenticated(user));
    } on Failure catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await signOutUseCase();
      final hasSeenOnboarding = await storageService.hasSeenOnboarding();
      emit(AuthUnauthenticated(hasSeenOnboarding: hasSeenOnboarding));
    } catch (_) {
      emit(const AuthUnauthenticated(hasSeenOnboarding: true));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final message = await forgotPasswordUseCase(event.email);
      emit(PasswordResetSuccess(message));
    } on Failure catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}

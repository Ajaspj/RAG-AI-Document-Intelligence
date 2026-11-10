import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  final bool hasSeenOnboarding;

  const AuthUnauthenticated({this.hasSeenOnboarding = false});

  @override
  List<Object?> get props => [hasSeenOnboarding];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordResetSuccess extends AuthState {
  final String message;

  const PasswordResetSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<String> call(String email) {
    return repository.forgotPassword(email);
  }
}

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<User> call(String fullName, String email, String password) {
    return repository.signUp(fullName, email, password);
  }
}

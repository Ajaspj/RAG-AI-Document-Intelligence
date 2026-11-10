import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUseCase {
  final AuthRepository repository;

  RestoreSessionUseCase(this.repository);

  Future<User?> call() {
    return repository.restoreSession();
  }
}

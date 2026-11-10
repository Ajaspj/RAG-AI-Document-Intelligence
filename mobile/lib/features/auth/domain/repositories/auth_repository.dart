import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signIn(String email, String password);
  Future<User> signUp(String fullName, String email, String password);
  Future<void> signOut();
  Future<User?> restoreSession();
  Future<String> forgotPassword(String email);
}

import '../models/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> loginWithCredentials(String phoneOrEmail, String password);
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<void> updatePreferredLanguage(String languageCode);
}

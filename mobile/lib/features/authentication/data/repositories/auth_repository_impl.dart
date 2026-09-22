import '../../../../core/security/secure_storage_service.dart';
import '../../../../data/datasources/local/user_local_data_source.dart';
import '../../../../domain/models/user.dart';
import '../../../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final UserLocalDataSource _userLocalDataSource;
  final TokenVault _tokenVault;

  AuthRepositoryImpl({
    required UserLocalDataSource userLocalDataSource,
    required TokenVault tokenVault,
  })  : _userLocalDataSource = userLocalDataSource,
        _tokenVault = tokenVault;

  @override
  Future<User?> getCurrentUser() async {
    final userId = await _tokenVault.getUserId();
    if (userId == null) return null;
    return await _userLocalDataSource.getUserById(userId);
  }

  @override
  Future<User> loginWithCredentials(String phoneOrEmail, String password) async {
    User? user = await _userLocalDataSource.getUserByPhoneOrEmail(phoneOrEmail);

    if (user == null) {
      final now = DateTime.now();
      user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        phoneOrEmail: phoneOrEmail,
        role: phoneOrEmail.contains('care') ? UserRole.caregiver : UserRole.patient,
        fullName: phoneOrEmail.contains('care') ? 'Caregiver Ananya' : 'Deka Da (দাদা)',
        preferredLanguage: 'as',
        createdAt: now,
        updatedAt: now,
      );
      await _userLocalDataSource.createUser(user);
    }

    await _tokenVault.saveAuthTokens(
      accessToken: 'mock_jwt_token_${user.id}',
      refreshToken: 'mock_refresh_token_${user.id}',
      userId: user.id,
      userRole: user.role == UserRole.patient ? 'PATIENT' : 'CAREGIVER',
    );

    return user;
  }

  @override
  Future<void> logout() async {
    await _tokenVault.clearAuth();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _tokenVault.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> updatePreferredLanguage(String languageCode) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        preferredLanguage: languageCode,
        updatedAt: DateTime.now(),
      );
      await _userLocalDataSource.updateUser(updated);
    }
  }
}

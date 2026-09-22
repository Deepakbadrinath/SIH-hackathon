import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ISecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class SecureStorageService implements ISecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

class TokenVault {
  static const String keyAccessToken = 'auth_access_token';
  static const String keyRefreshToken = 'auth_refresh_token';
  static const String keyUserId = 'auth_user_id';
  static const String keyUserRole = 'auth_user_role';

  final ISecureStorageService _storage;

  TokenVault(this._storage);

  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
  }) async {
    await _storage.write(keyAccessToken, accessToken);
    await _storage.write(keyRefreshToken, refreshToken);
    await _storage.write(keyUserId, userId);
    await _storage.write(keyUserRole, userRole);
  }

  Future<String?> getAccessToken() async => await _storage.read(keyAccessToken);
  Future<String?> getRefreshToken() async => await _storage.read(keyRefreshToken);
  Future<String?> getUserId() async => await _storage.read(keyUserId);
  Future<String?> getUserRole() async => await _storage.read(keyUserRole);

  Future<void> clearAuth() async {
    await _storage.delete(keyAccessToken);
    await _storage.delete(keyRefreshToken);
    await _storage.delete(keyUserId);
    await _storage.delete(keyUserRole);
  }
}

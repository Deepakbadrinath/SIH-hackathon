import 'package:flutter/foundation.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../domain/models/auth_state.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;
  AuthState _state = const AuthState();

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository {
    checkAuthStatus();
  }

  AuthState get state => _state;
  bool get isLoading => _state.status == AuthStatus.authenticating;
  String? get errorMessage => _state.errorMessage;

  Future<void> checkAuthStatus() async {
    _state = _state.copyWith(status: AuthStatus.authenticating);
    notifyListeners();

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _state = _state.copyWith(
          status: AuthStatus.authenticated,
          currentUser: user,
          errorMessage: null,
        );
      } else {
        _state = _state.copyWith(
          status: AuthStatus.unauthenticated,
          currentUser: null,
        );
      }
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<bool> login(String phoneOrEmail, String password) async {
    _state = _state.copyWith(status: AuthStatus.authenticating);
    notifyListeners();

    try {
      final user = await _authRepository.loginWithCredentials(phoneOrEmail, password);
      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        currentUser: user,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithPhone(String phone) async {
    return login(phone, 'elder_demo_pass');
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _state = const AuthState(status: AuthStatus.unauthenticated);
    notifyListeners();
  }
}

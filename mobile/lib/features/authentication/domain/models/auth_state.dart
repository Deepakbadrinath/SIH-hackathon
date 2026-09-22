import '../../../../domain/models/user.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? currentUser;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.currentUser,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && currentUser != null;
  bool get isPatient => currentUser?.role == UserRole.patient;
  bool get isCaregiver => currentUser?.role == UserRole.caregiver;

  AuthState copyWith({
    AuthStatus? status,
    User? currentUser,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

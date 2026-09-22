abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => '$runtimeType: $message (${code ?? "NO_CODE"})';
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class SyncFailure extends Failure {
  const SyncFailure(super.message, [super.code]);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

class VoiceFailure extends Failure {
  const VoiceFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

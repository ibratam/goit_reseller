import '../domain/app_user.dart';
import '../domain/auth_session.dart';

abstract class AuthService {
  Future<AuthSession> login({
    required String username,
    required String password,
    String deviceName = 'mobile-app',
  });

  Future<AppUser> fetchCurrentUser(AuthSession session);

  Future<void> logout(AuthSession session);
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

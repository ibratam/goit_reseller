import 'app_user.dart';

class AuthSession {
  const AuthSession({
    required this.tokenType,
    required this.token,
    required this.user,
  });

  final String tokenType;
  final String token;
  final AppUser user;

  String get authorizationValue => '$tokenType $token';

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    if (rawUser is! Map) {
      throw const FormatException('Missing user payload.');
    }

    return AuthSession(
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      token: json['token']?.toString() ?? '',
      user: AppUser.fromJson(Map<String, dynamic>.from(rawUser)),
    );
  }

  AuthSession copyWith({
    AppUser? user,
  }) {
    return AuthSession(
      tokenType: tokenType,
      token: token,
      user: user ?? this.user,
    );
  }
}

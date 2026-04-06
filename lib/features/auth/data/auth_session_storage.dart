import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_session.dart';

class StoredAuthSession {
  const StoredAuthSession({
    required this.session,
    required this.expiresAt,
  });

  final AuthSession session;
  final DateTime expiresAt;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);
}

class AuthSessionStorage {
  static const Duration sessionLifetime = Duration(hours: 1);

  static const String _sessionKey = 'auth.session.json';
  static const String _expiresAtKey = 'auth.session.expires_at_ms';

  Future<StoredAuthSession?> loadSession() async {
    final preferences = await SharedPreferences.getInstance();
    final sessionJson = preferences.getString(_sessionKey);
    final expiresAtMillis = preferences.getInt(_expiresAtKey);

    if (sessionJson == null || expiresAtMillis == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(sessionJson);
      if (decoded is! Map) {
        await clear();
        return null;
      }

      final stored = StoredAuthSession(
        session: AuthSession.fromJson(Map<String, dynamic>.from(decoded)),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMillis),
      );

      if (stored.isExpired) {
        await clear();
        return null;
      }

      return stored;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> saveSession(
    AuthSession session, {
    required DateTime expiresAt,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
    await preferences.setInt(
      _expiresAtKey,
      expiresAt.millisecondsSinceEpoch,
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
    await preferences.remove(_expiresAtKey);
  }
}

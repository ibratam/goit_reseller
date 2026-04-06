import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../domain/app_user.dart';
import '../domain/auth_session.dart';
import 'auth_service.dart';

class ApiAuthService implements AuthService {
  const ApiAuthService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
    String? deviceName,
  }) async {
    final resolvedDeviceName = deviceName ?? ApiConfig.deviceName;

    try {
      final response = await _apiClient.post(
        '/api/users/login',
        body: {
          'username': username.trim(),
          'password': password,
          'device_name': resolvedDeviceName,
        },
      );

      if (response.data['success'] == true) {
        return AuthSession.fromJson(response.data);
      }

      throw AuthException(
        _resolveMessage(
          response.data,
          fallback: 'Login failed.',
        ),
      );
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } on FormatException {
      throw const AuthException('The login response is missing required data.');
    }
  }

  @override
  Future<AppUser> fetchCurrentUser(AuthSession session) async {
    try {
      final response = await _apiClient.get(
        '/api/users',
        authorization: session.authorizationValue,
      );

      if (response.data['success'] == true) {
        final rawUser = response.data['user'];
        if (rawUser is! Map) {
          throw const FormatException('Missing user payload.');
        }
        return AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      }

      throw AuthException(
        _resolveMessage(
          response.data,
          fallback: 'Unable to load your account.',
        ),
      );
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } on FormatException {
      throw const AuthException('The account response is missing required data.');
    }
  }

  @override
  Future<void> logout(AuthSession session) async {
    try {
      final response = await _apiClient.post(
        '/api/users/logout',
        authorization: session.authorizationValue,
      );

      if (response.data['success'] == true) {
        return;
      }

      throw AuthException(
        _resolveMessage(
          response.data,
          fallback: 'Logout failed.',
        ),
      );
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
  }

  String _resolveMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final message = formatApiMessage(
      data['message']?.toString(),
      fallback: fallback,
    );
    final details = data['details']?.toString().trim();
    if (details != null && details.isNotEmpty) {
      return '$message: $details';
    }
    return message;
  }
}

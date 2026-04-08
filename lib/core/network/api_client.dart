import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    void Function()? onUnauthorized,
  })  : _baseUrl = baseUrl.trim(),
        _httpClient = httpClient ?? http.Client(),
        _onUnauthorized = onUnauthorized;

  final String _baseUrl;
  final http.Client _httpClient;
  final void Function()? _onUnauthorized;
  bool _isNotifyingUnauthorized = false;

  Future<ApiResponse> get(
    String path, {
    String? authorization,
    Map<String, String?> queryParameters = const {},
  }) {
    return _send(
      method: 'GET',
      path: path,
      authorization: authorization,
      queryParameters: queryParameters,
    );
  }

  Future<ApiResponse> post(
    String path, {
    String? authorization,
    Map<String, String?> queryParameters = const {},
    Map<String, dynamic>? body,
  }) {
    return _send(
      method: 'POST',
      path: path,
      authorization: authorization,
      queryParameters: queryParameters,
      body: body,
    );
  }

  void close() {
    _httpClient.close();
  }

  Future<ApiResponse> _send({
    required String method,
    required String path,
    String? authorization,
    Map<String, String?> queryParameters = const {},
    Map<String, dynamic>? body,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const ApiException(
        'Set API_BASE_URL before using the app.',
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (authorization != null && authorization.trim().isNotEmpty) {
      headers['Authorization'] = authorization;
    }

    final hasAuthorization =
        authorization != null && authorization.trim().isNotEmpty;

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    final uri = _buildUri(path, queryParameters: queryParameters);

    try {
      late final http.Response response;

      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(const Duration(seconds: 20));
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      if (response.body.trim().isEmpty) {
        if (_isUnauthorizedResponse(
          statusCode: response.statusCode,
          data: const <String, dynamic>{},
          hasAuthorization: hasAuthorization,
        )) {
          _notifyUnauthorized();
          throw ApiUnauthorizedException(
            'Session expired. Please sign in again.',
            statusCode: response.statusCode,
          );
        }

        return ApiResponse(
          statusCode: response.statusCode,
          data: const <String, dynamic>{},
        );
      }

      final dynamic decodedBody = jsonDecode(response.body);
      if (decodedBody is! Map) {
        throw ApiException(
          'The server returned an unexpected response.',
          statusCode: response.statusCode,
        );
      }

      final data = Map<String, dynamic>.from(decodedBody);
      if (_isUnauthorizedResponse(
        statusCode: response.statusCode,
        data: data,
        hasAuthorization: hasAuthorization,
      )) {
        _notifyUnauthorized();
        throw ApiUnauthorizedException(
          _resolveUnauthorizedMessage(data),
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        statusCode: response.statusCode,
        data: data,
      );
    } on TimeoutException {
      throw const ApiException('The request timed out.');
    } on FormatException {
      throw const ApiException('The server returned invalid JSON.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Unable to connect to the API server.');
    }
  }

  bool _isUnauthorizedResponse({
    required int statusCode,
    required Map<String, dynamic> data,
    required bool hasAuthorization,
  }) {
    if (!hasAuthorization) {
      return false;
    }

    if (statusCode == 401 || statusCode == 403) {
      return true;
    }

    final message = data['message']?.toString().trim().toLowerCase() ?? '';
    if (message.isEmpty) {
      return false;
    }

    return message.contains('unauthenticated') ||
        message.contains('unauthorized') ||
        message.contains('invalid token') ||
        message.contains('token expired') ||
        message.contains('session expired');
  }

  String _resolveUnauthorizedMessage(Map<String, dynamic> data) {
    final message = data['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return 'Session expired. Please sign in again.';
  }

  void _notifyUnauthorized() {
    if (_isNotifyingUnauthorized) {
      return;
    }

    _isNotifyingUnauthorized = true;
    scheduleMicrotask(() {
      try {
        _onUnauthorized?.call();
      } finally {
        _isNotifyingUnauthorized = false;
      }
    });
  }

  Uri _buildUri(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) {
    final normalizedBase =
        _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath');

    final effectiveQueryParameters = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value?.trim();
      if (value != null && value.isNotEmpty) {
        effectiveQueryParameters[entry.key] = value;
      }
    }

    if (effectiveQueryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: effectiveQueryParameters);
  }
}

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.data,
  });

  final int statusCode;
  final Map<String, dynamic> data;

  bool get isSuccessStatus => statusCode >= 200 && statusCode < 300;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
}

class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException(super.message, {super.statusCode});
}

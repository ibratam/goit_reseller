import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl.trim(),
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

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
    Map<String, dynamic>? body,
  }) {
    return _send(
      method: 'POST',
      path: path,
      authorization: authorization,
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

      return ApiResponse(
        statusCode: response.statusCode,
        data: Map<String, dynamic>.from(decodedBody),
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

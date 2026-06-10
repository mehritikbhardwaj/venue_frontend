import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'failure.dart';

/// Thin HTTP wrapper. Owns the base URL and injects the current user id as the
/// `X-User-Id` header. Returns decoded JSON or throws a typed [Failure].
///
/// Repositories are the only callers; widgets must never touch this directly.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Current acting user id, set after login. Sent on every request as X-User-Id.
  int? userId;

  static const _timeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (userId != null) 'X-User-Id': '$userId',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) =>
      Uri.parse('${AppConfig.apiBaseUrl}$path').replace(
        queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
      );

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    final uri = _uri(path, query);
    return _send('GET', uri, () => _client.get(uri, headers: _headers));
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    final uri = _uri(path);
    final encoded = jsonEncode(body ?? {});
    return _send(
      'POST',
      uri,
      () => _client.post(uri, headers: _headers, body: encoded),
      body: encoded,
    );
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) {
    final uri = _uri(path);
    final encoded = jsonEncode(body ?? {});
    return _send(
      'PATCH',
      uri,
      () => _client.patch(uri, headers: _headers, body: encoded),
      body: encoded,
    );
  }

  Future<dynamic> delete(String path) {
    final uri = _uri(path);
    return _send('DELETE', uri, () => _client.delete(uri, headers: _headers));
  }

  /// Executes the request, maps transport errors to [NetworkFailure] and
  /// HTTP error statuses to typed failures. 204 returns null.
  Future<dynamic> _send(
    String method,
    Uri uri,
    Future<http.Response> Function() request, {
    String? body,
  }) async {
    _logRequest(method, uri, body: body);

    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on TimeoutException {
      throw const NetworkFailure('Request timed out. Try again.');
    } catch (_) {
      throw const NetworkFailure();
    }

    _logResponse(method, uri, res);

    if (res.statusCode == 204 || res.body.isEmpty) return null;

    final dynamic decoded = _tryDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final serverMsg = (decoded is Map && decoded['error'] is String)
        ? decoded['error'] as String
        : 'Request failed (${res.statusCode})';

    if (res.statusCode == 409) throw SlotTakenFailure(serverMsg);
    throw ApiFailure(res.statusCode, serverMsg);
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  void _logRequest(String method, Uri uri, {String? body}) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('→ $method $uri');
    if (_headers.isNotEmpty) {
      buffer.write('\n  headers: $_headers');
    }
    if (body != null && body.isNotEmpty) {
      buffer.write('\n  body: $body');
    }
    debugPrint(buffer.toString());
  }

  void _logResponse(String method, Uri uri, http.Response res) {
    if (!kDebugMode) return;
    debugPrint('← $method $uri [${res.statusCode}]');
    if (res.body.isNotEmpty) {
      debugPrint('  response: ${res.body}');
    }
  }

  void dispose() => _client.close();
}

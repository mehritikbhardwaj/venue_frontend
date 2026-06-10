import 'dart:async';
import 'dart:convert';

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

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send(() => _client.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  /// Executes the request, maps transport errors to [NetworkFailure] and
  /// HTTP error statuses to typed failures. 204 returns null.
  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on TimeoutException {
      throw const NetworkFailure('Request timed out. Try again.');
    } catch (_) {
      throw const NetworkFailure();
    }

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

  void dispose() => _client.close();
}

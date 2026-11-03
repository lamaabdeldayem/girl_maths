// lib/services/firebase_service.dart
//
// Backend: Firebase Realtime Database accessed through its REST API with the
// `http` package (Lecture 6, part 2). The database URL comes from the .env
// file (Lecture 6, part 4) so it is not hard-coded.
//
// Data layout:
//   /users/<deviceUserId>/expenses/<expenseId>  -> Expense.toJson()
//   /users/<deviceUserId>/goals/<goalId>        -> SavingsGoal.toJson()
//
// We use PUT with our own client-generated ids, so writes are idempotent and
// an expense keeps the same id locally and on the server.
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FirebaseException implements Exception {
  final String message;
  FirebaseException(this.message);
  @override
  String toString() => message;
}

class FirebaseService {
  FirebaseService({required this.userId, http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _overrideUrl = baseUrl;

  final String userId;
  final http.Client _client;
  final String? _overrideUrl;

  static const _timeout = Duration(seconds: 10);

  String get _baseUrl {
    if (_overrideUrl != null) return _overrideUrl;
    String? url;
    try {
      url = dotenv.env['FIREBASE_DB_URL'];
    } catch (_) {
      url = null; // dotenv not loaded (e.g. in tests)
    }
    var clean = (url ?? '').trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  String? get _authParam {
    try {
      final secret = dotenv.env['FIREBASE_AUTH'];
      return (secret == null || secret.isEmpty) ? null : secret;
    } catch (_) {
      return null;
    }
  }

  /// false when no database URL was configured -> the app runs offline-only.
  bool get isConfigured => _baseUrl.startsWith('https://');

  Uri _uri(String path) {
    final auth = _authParam;
    final query = auth == null ? '' : '?auth=$auth';
    return Uri.parse('$_baseUrl/users/$userId/$path.json$query');
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw FirebaseException(
          'Firebase error ${res.statusCode}: ${res.body}');
    }
  }

  /// Returns {id: json} for a whole collection ("expenses" or "goals").
  Future<Map<String, Map<String, dynamic>>> fetchCollection(
      String collection) async {
    if (!isConfigured) throw FirebaseException('Firebase is not configured');
    final res = await _client.get(_uri(collection)).timeout(_timeout);
    _check(res);
    final decoded = json.decode(res.body);
    if (decoded == null) return {};
    final result = <String, Map<String, dynamic>>{};
    (decoded as Map<String, dynamic>).forEach((key, value) {
      if (value is Map) result[key] = Map<String, dynamic>.from(value);
    });
    return result;
  }

  Future<void> put(String collection, String id, Map<String, dynamic> body) async {
    if (!isConfigured) throw FirebaseException('Firebase is not configured');
    final res = await _client
        .put(_uri('$collection/$id'), body: json.encode(body))
        .timeout(_timeout);
    _check(res);
  }

  Future<void> delete(String collection, String id) async {
    if (!isConfigured) throw FirebaseException('Firebase is not configured');
    final res = await _client.delete(_uri('$collection/$id')).timeout(_timeout);
    _check(res);
  }
}

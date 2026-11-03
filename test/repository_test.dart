// test/repository_test.dart – offline-first cache + Firebase sync.
import 'dart:convert';

import 'package:girl_maths/models/expense.dart';
import 'package:girl_maths/services/firebase_service.dart';
import 'package:girl_maths/services/local_store.dart';
import 'package:girl_maths/services/sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Fake Firebase Realtime Database kept in a map.
class FakeServer {
  final Map<String, Map<String, dynamic>> data = {};
  bool online = true;
  final requests = <String>[];

  MockClient get client => MockClient((req) async {
        if (!online) throw http.ClientException('no internet');
        requests.add('${req.method} ${req.url.path}');
        final parts = req.url.path.replaceAll('.json', '').split('/');
        // /users/<uid>/<collection>[/<id>]
        final collection = parts[3];
        final id = parts.length > 4 ? parts[4] : null;
        final col = data.putIfAbsent(collection, () => {});
        switch (req.method) {
          case 'GET':
            return http.Response(col.isEmpty ? 'null' : json.encode(col), 200);
          case 'PUT':
            col[id!] = json.decode(req.body) as Map<String, dynamic>;
            return http.Response(req.body, 200);
          case 'DELETE':
            col.remove(id);
            return http.Response('null', 200);
        }
        return http.Response('bad', 400);
      });
}

void main() {
  late FakeServer server;
  late InMemoryLocalStore local;
  late SyncRepository repo;

  setUp(() {
    server = FakeServer();
    local = InMemoryLocalStore();
    repo = SyncRepository(
      local: local,
      remote: FirebaseService(
        userId: 'u1',
        client: server.client,
        baseUrl: 'https://test-db.firebaseio.com',
      ),
    );
  });

  Expense sample([String title = 'Latte']) => Expense(
        title: title,
        amount: 75,
        date: DateTime(2026, 11, 1),
        categoryId: 'coffee',
      );

  test('online save writes cache and server and marks synced', () async {
    final saved = await repo.saveExpense(sample());
    expect(saved.isSynced, isTrue);
    expect(server.data['expenses']!.containsKey(saved.id), isTrue);
    expect((await local.fetchExpenses()).single.isSynced, isTrue);
    expect(server.requests.single, 'PUT /users/u1/expenses/${saved.id}.json');
  });

  test('offline save stays in cache and is pushed later', () async {
    server.online = false;
    final saved = await repo.saveExpense(sample());
    expect(saved.isSynced, isFalse);
    expect(await repo.pendingCount(), 1);

    server.online = true;
    final list = await repo.refreshExpenses();
    expect(list.single.isSynced, isTrue);
    expect(server.data['expenses']!.length, 1);
    expect(await repo.pendingCount(), 0);
  });

  test('offline delete is queued and replayed', () async {
    final saved = await repo.saveExpense(sample());
    server.online = false;
    await repo.deleteExpense(saved.id);
    expect(await local.fetchExpenses(), isEmpty);
    expect(await repo.pendingCount(), 1);

    server.online = true;
    await repo.refreshExpenses();
    expect(server.data['expenses'], isEmpty);
    expect(await repo.pendingCount(), 0);
  });

  test('refresh pulls items added on another device and keeps local photos',
      () async {
    final mine = await repo.saveExpense(
        sample('Mine').copyWith(imagePath: '/photos/mine.jpg'));
    server.data['expenses']!['other1'] = sample('From tablet').toJson();

    final list = await repo.refreshExpenses();
    expect(list.map((e) => e.title), containsAll(['Mine', 'From tablet']));
    expect(list.firstWhere((e) => e.id == mine.id).imagePath,
        '/photos/mine.jpg');
  });

  test('refresh throws when offline so the UI can keep the cache', () async {
    await repo.saveExpense(sample());
    server.online = false;
    await expectLater(
        repo.refreshExpenses(), throwsA(isA<http.ClientException>()));
    expect((await repo.cachedExpenses()).length, 1);
  });

  test('without a database URL the app works offline-only', () async {
    final offline = SyncRepository(
      local: InMemoryLocalStore(),
      remote: FirebaseService(userId: 'u1', baseUrl: ''),
    );
    expect(offline.hasBackend, isFalse);
    final saved = await offline.saveExpense(sample());
    expect(saved.isSynced, isFalse);
    expect((await offline.refreshExpenses()).length, 1);
  });
}

// lib/services/database_helper.dart
//
// SQLite = the local cache / offline store (singleton, as in Lecture 3).
//
// Relational model (v2):
//   categories(id PK, emoji, name_en, name_ar, color)
//   expenses(id PK, title, amount, date, category_id FK -> categories.id,
//            note, image_path, is_synced, updated_at)
//   savings_goals(id PK, title, emoji, target_amount, saved_amount, deadline,
//                 image_path, created_at, is_synced)
//   pending_deletes(id PK, collection)   -- sync queue for offline deletes
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../models/savings_goal.dart';
import 'local_store.dart';

class DatabaseHelper implements LocalStore {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const _dbName = 'masroufi.db';
  static const _dbVersion = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        emoji TEXT NOT NULL,
        name_en TEXT NOT NULL,
        name_ar TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category_id TEXT NOT NULL REFERENCES categories(id),
        note TEXT,
        image_path TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        emoji TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        deadline TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_deletes (
        id TEXT PRIMARY KEY,
        collection TEXT NOT NULL
      )
    ''');
    final batch = db.batch();
    for (final c in ExpenseCategory.all) {
      batch.insert('categories', c.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// v1 had `expenses(id INTEGER, title, amount, date, category)`.
  /// We keep the user's old expenses and move them into the v2 schema.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final old = await db.query('expenses');
      await db.execute('ALTER TABLE expenses RENAME TO expenses_v1');
      await _createDB(db, newVersion);
      final batch = db.batch();
      for (final row in old) {
        final e = Expense(
          id: 'legacy${row['id']}',
          title: row['title'] as String,
          amount: (row['amount'] as num).toDouble(),
          date: DateTime.parse(row['date'] as String),
          categoryId:
              ExpenseCategory.migrateLegacy((row['category'] ?? '') as String),
        );
        batch.insert('expenses', e.toMap());
      }
      await batch.commit(noResult: true);
      await db.execute('DROP TABLE expenses_v1');
    }
  }

  // ---------------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------------
  @override
  Future<void> upsertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<Expense>> fetchExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map(Expense.fromMap).toList();
  }

  @override
  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Overwrites the cache with the server copy (Lecture 6 caching flow),
  /// but keeps local-only (unsynced) rows so nothing is lost offline.
  @override
  Future<void> replaceSyncedExpenses(List<Expense> fromServer) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('expenses', where: 'is_synced = 1');
      for (final e in fromServer) {
        await txn.insert('expenses', e.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Savings goals
  // ---------------------------------------------------------------------------
  @override
  Future<void> upsertGoal(SavingsGoal goal) async {
    final db = await database;
    await db.insert('savings_goals', goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<SavingsGoal>> fetchGoals() async {
    final db = await database;
    final maps = await db.query('savings_goals', orderBy: 'created_at ASC');
    return maps.map(SavingsGoal.fromMap).toList();
  }

  @override
  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> replaceSyncedGoals(List<SavingsGoal> fromServer) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('savings_goals', where: 'is_synced = 1');
      for (final g in fromServer) {
        await txn.insert('savings_goals', g.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Sync queue for deletes made while offline
  // ---------------------------------------------------------------------------
  @override
  Future<void> addPendingDelete(String id, String collection) async {
    final db = await database;
    await db.insert('pending_deletes', {'id': id, 'collection': collection},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<MapEntry<String, String>>> fetchPendingDeletes() async {
    final db = await database;
    final rows = await db.query('pending_deletes');
    return rows
        .map((r) => MapEntry(r['id'] as String, r['collection'] as String))
        .toList();
  }

  @override
  Future<void> removePendingDelete(String id) async {
    final db = await database;
    await db.delete('pending_deletes', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('savings_goals');
    await db.delete('pending_deletes');
  }
}

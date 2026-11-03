// lib/models/expense.dart
import 'category.dart';

class Expense {
  /// Client-generated id (also used as the Firebase key, so the same
  /// expense has the same id locally and on the server).
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String? note;

  /// Local file path of an optional receipt / outfit photo.
  final String? imagePath;

  /// false while the expense only exists in the local cache and still has
  /// to be pushed to Firebase.
  final bool isSynced;
  final DateTime updatedAt;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.note,
    this.imagePath,
    this.isSynced = false,
    DateTime? updatedAt,
  })  : id = id ?? generateId(),
        updatedAt = updatedAt ?? DateTime.now();

  ExpenseCategory get category => ExpenseCategory.byId(categoryId);

  static int _counter = 0;

  /// Time-based id that is valid as a Firebase key (no . # $ [ ] /).
  static String generateId() {
    _counter = (_counter + 1) % 1000;
    return 'e${DateTime.now().microsecondsSinceEpoch}${_counter.toString().padLeft(3, '0')}';
  }

  Expense copyWith({
    String? title,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? note,
    String? imagePath,
    bool clearImage = false,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // SQLite (local cache)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'note': note,
      'image_path': imagePath,
      'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'].toString(),
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: ExpenseCategory.migrateLegacy(
        (map['category_id'] ?? map['category'] ?? 'other') as String,
      ),
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
      isSynced: (map['is_synced'] ?? 0) == 1,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Firebase Realtime Database (JSON over HTTP)
  // The image is a local file, so only the path stays on this device.
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'note': note,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(String id, Map<String, dynamic> json,
      {String? localImagePath}) {
    return Expense(
      id: id,
      title: (json['title'] ?? '') as String,
      amount: (json['amount'] as num? ?? 0).toDouble(),
      date: DateTime.tryParse((json['date'] ?? '') as String) ??
          DateTime.now(),
      categoryId:
          ExpenseCategory.migrateLegacy((json['categoryId'] ?? 'other') as String),
      note: json['note'] as String?,
      imagePath: localImagePath,
      isSynced: true,
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '') as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.title == title &&
      other.amount == amount &&
      other.date == date &&
      other.categoryId == categoryId &&
      other.note == note &&
      other.imagePath == imagePath;

  @override
  int get hashCode =>
      Object.hash(id, title, amount, date, categoryId, note, imagePath);
}

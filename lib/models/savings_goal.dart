// lib/models/savings_goal.dart
//
// A "wishlist" savings goal, e.g. "New bag 👜 – 3000 EGP".

class SavingsGoal {
  final String id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final String? imagePath;
  final DateTime createdAt;
  final bool isSynced;

  SavingsGoal({
    String? id,
    required this.title,
    this.emoji = '👜',
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    this.imagePath,
    DateTime? createdAt,
    this.isSynced = false,
  })  : id = id ?? 'g${DateTime.now().microsecondsSinceEpoch}',
        createdAt = createdAt ?? DateTime.now();

  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);

  double get remaining =>
      (targetAmount - savedAmount).clamp(0.0, double.infinity);

  bool get isCompleted => savedAmount >= targetAmount && targetAmount > 0;

  /// How much should be saved per day to hit the deadline.
  double? dailyNeeded(DateTime now) {
    if (deadline == null || isCompleted) return null;
    final days = deadline!.difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days <= 0) return remaining;
    return remaining / days;
  }

  SavingsGoal copyWith({
    String? title,
    String? emoji,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    bool clearDeadline = false,
    String? imagePath,
    bool clearImage = false,
    bool? isSynced,
  }) {
    return SavingsGoal(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      createdAt: createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'deadline': deadline?.toIso8601String(),
        'image_path': imagePath,
        'created_at': createdAt.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
        id: map['id'] as String,
        title: map['title'] as String,
        emoji: (map['emoji'] ?? '👜') as String,
        targetAmount: (map['target_amount'] as num).toDouble(),
        savedAmount: (map['saved_amount'] as num? ?? 0).toDouble(),
        deadline: map['deadline'] != null
            ? DateTime.parse(map['deadline'] as String)
            : null,
        imagePath: map['image_path'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        isSynced: (map['is_synced'] ?? 0) == 1,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'emoji': emoji,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'deadline': deadline?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavingsGoal.fromJson(String id, Map<String, dynamic> json,
          {String? localImagePath}) =>
      SavingsGoal(
        id: id,
        title: (json['title'] ?? '') as String,
        emoji: (json['emoji'] ?? '👜') as String,
        targetAmount: (json['targetAmount'] as num? ?? 0).toDouble(),
        savedAmount: (json['savedAmount'] as num? ?? 0).toDouble(),
        deadline: json['deadline'] != null
            ? DateTime.tryParse(json['deadline'] as String)
            : null,
        imagePath: localImagePath,
        createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String),
        isSynced: true,
      );
}

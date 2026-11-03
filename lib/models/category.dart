// lib/models/category.dart
//
// Expense categories ("Girl Math justifications").
// In the relational model this is the `categories` lookup table; the same
// list is used to seed that table in SQLite (see DatabaseHelper).
import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String emoji;
  final String nameEn;
  final String nameAr;
  final String justificationEn;
  final String justificationAr;
  final Color color;

  const ExpenseCategory({
    required this.id,
    required this.emoji,
    required this.nameEn,
    required this.nameAr,
    required this.justificationEn,
    required this.justificationAr,
    required this.color,
  });

  String label(bool arabic) => arabic ? nameAr : nameEn;
  String justification(bool arabic) =>
      arabic ? justificationAr : justificationEn;

  Map<String, dynamic> toMap() => {
        'id': id,
        'emoji': emoji,
        'name_en': nameEn,
        'name_ar': nameAr,
        'color': color.toARGB32(),
      };

  // ---------------------------------------------------------------------------
  // Static catalogue
  // ---------------------------------------------------------------------------
  static const List<ExpenseCategory> all = [
    ExpenseCategory(
      id: 'coffee',
      emoji: '☕',
      nameEn: 'Iced Coffee',
      nameAr: 'آيس كوفي',
      justificationEn: 'Under 100 is basically free',
      justificationAr: 'أقل من ١٠٠ يعني ببلاش',
      color: Color(0xFFFF2A7A),
    ),
    ExpenseCategory(
      id: 'treat',
      emoji: '🧁',
      nameEn: 'Daily Treat',
      nameAr: 'دلع يومي',
      justificationEn: 'I deserved it today',
      justificationAr: 'أنا أستاهل النهارده',
      color: Color(0xFFFF70A6),
    ),
    ExpenseCategory(
      id: 'fashion',
      emoji: '👗',
      nameEn: 'Cost Per Wear',
      nameAr: 'تمن اللبسة',
      justificationEn: 'Wear it 50 times = almost free',
      justificationAr: 'هلبسه ٥٠ مرة يبقى ببلاش',
      color: Color(0xFF9D4EDD),
    ),
    ExpenseCategory(
      id: 'selfcare',
      emoji: '💅',
      nameEn: 'Self Care & Nails',
      nameAr: 'عناية ومناكير',
      justificationEn: 'Mental health investment',
      justificationAr: 'استثمار في الصحة النفسية',
      color: Color(0xFFF48FB1),
    ),
    ExpenseCategory(
      id: 'food',
      emoji: '🍣',
      nameEn: 'Food & Dining',
      nameAr: 'أكل وخروج',
      justificationEn: 'Split the bill = half price',
      justificationAr: 'قسمنا الحساب يبقى بنص التمن',
      color: Color(0xFFFFA726),
    ),
    ExpenseCategory(
      id: 'transport',
      emoji: '🚕',
      nameEn: 'Transport',
      nameAr: 'مواصلات',
      justificationEn: 'Safety first, Uber it',
      justificationAr: 'الأمان أهم، أوبر',
      color: Color(0xFF4FC3F7),
    ),
    ExpenseCategory(
      id: 'bills',
      emoji: '💸',
      nameEn: 'Bills (Ugh)',
      nameAr: 'فواتير (أوف)',
      justificationEn: 'Unfortunately mandatory',
      justificationAr: 'للأسف إجباري',
      color: Color(0xFF90A4AE),
    ),
    ExpenseCategory(
      id: 'other',
      emoji: '🛍️',
      nameEn: 'Other Investments',
      nameAr: 'استثمارات تانية',
      justificationEn: 'It was on sale, so I saved money',
      justificationAr: 'كان عليه خصم يعني وفرت',
      color: Color(0xFF81C784),
    ),
  ];

  static ExpenseCategory byId(String id) => all.firstWhere(
        (c) => c.id == id,
        orElse: () => all.last,
      );

  /// Maps the category strings stored by the first version of the app
  /// (e.g. "Iced Coffee ☕") to the new category ids.
  static String migrateLegacy(String value) {
    if (all.any((c) => c.id == value)) return value;
    final lower = value.toLowerCase();
    if (lower.contains('coffee')) return 'coffee';
    if (lower.contains('treat')) return 'treat';
    if (lower.contains('wear')) return 'fashion';
    if (lower.contains('nail') || lower.contains('self care')) {
      return 'selfcare';
    }
    if (lower.contains('bill')) return 'bills';
    if (lower.contains('food')) return 'food';
    return 'other';
  }
}

// lib/providers/settings_provider.dart
//
// App settings persisted with SharedPreferences (Lecture 5):
// theme, language, currency, monthly budget, profile, girl-math threshold.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Currency {
  final String code;
  final String symbolEn;
  final String symbolAr;
  const Currency(this.code, this.symbolEn, this.symbolAr);

  static const all = [
    Currency('EGP', 'EGP', 'ج.م'),
    Currency('USD', '\$', '\$'),
    Currency('EUR', '€', '€'),
    Currency('SAR', 'SAR', 'ر.س'),
    Currency('AED', 'AED', 'د.إ'),
  ];

  static Currency byCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => all.first);
}

class SettingsProvider with ChangeNotifier {
  SettingsProvider(this._prefs) {
    _load();
  }

  /// Convenience for main(): loads prefs before the first frame so the
  /// right theme/language is used immediately (no flash).
  static Future<SettingsProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsProvider(prefs);
  }

  final SharedPreferences _prefs;

  static const _kTheme = 'themeMode';
  static const _kLegacyDark = 'isDarkMode'; // key used by the first version
  static const _kLang = 'languageCode';
  static const _kCurrency = 'currencyCode';
  static const _kBudget = 'monthlyBudget';
  static const _kName = 'userName';
  static const _kAvatar = 'profileImagePath';
  static const _kUserId = 'userId';
  static const _kLastSync = 'lastSync';
  static const _kFree = 'basicallyFreeThreshold';

  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'en';
  String _currencyCode = 'EGP';
  double _monthlyBudget = 6000;
  String _userName = '';
  String? _profileImagePath;
  late String _userId;
  DateTime? _lastSync;
  double _freeThreshold = 100;

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  bool get isArabic => _languageCode == 'ar';
  Locale get locale => Locale(_languageCode);
  Currency get currency => Currency.byCode(_currencyCode);
  String get currencySymbol => isArabic ? currency.symbolAr : currency.symbolEn;
  double get monthlyBudget => _monthlyBudget;
  String get userName => _userName;
  String? get profileImagePath => _profileImagePath;
  String get userId => _userId;
  DateTime? get lastSync => _lastSync;
  double get freeThreshold => _freeThreshold;

  void _load() {
    final storedTheme = _prefs.getString(_kTheme);
    if (storedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == storedTheme,
        orElse: () => ThemeMode.system,
      );
    } else if (_prefs.getBool(_kLegacyDark) != null) {
      _themeMode =
          _prefs.getBool(_kLegacyDark)! ? ThemeMode.dark : ThemeMode.light;
    }
    _languageCode = _prefs.getString(_kLang) ?? 'en';
    _currencyCode = _prefs.getString(_kCurrency) ?? 'EGP';
    _monthlyBudget = _prefs.getDouble(_kBudget) ?? 6000;
    _userName = _prefs.getString(_kName) ?? '';
    _profileImagePath = _prefs.getString(_kAvatar);
    _freeThreshold = _prefs.getDouble(_kFree) ?? 100;
    final sync = _prefs.getString(_kLastSync);
    _lastSync = sync == null ? null : DateTime.tryParse(sync);

    // Anonymous per-install id used as the Firebase path (no login needed).
    final existingId = _prefs.getString(_kUserId);
    if (existingId != null) {
      _userId = existingId;
    } else {
      final rnd = Random();
      _userId = 'u${DateTime.now().millisecondsSinceEpoch}'
          '${rnd.nextInt(1 << 32).toRadixString(36)}';
      _prefs.setString(_kUserId, _userId);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    notifyListeners();
    await _prefs.setString(_kLang, code);
  }

  Future<void> setCurrency(String code) async {
    _currencyCode = code;
    notifyListeners();
    await _prefs.setString(_kCurrency, code);
  }

  Future<void> setMonthlyBudget(double value) async {
    _monthlyBudget = value;
    notifyListeners();
    await _prefs.setDouble(_kBudget, value);
  }

  Future<void> setUserName(String value) async {
    _userName = value.trim();
    notifyListeners();
    await _prefs.setString(_kName, _userName);
  }

  Future<void> setProfileImage(String? path) async {
    _profileImagePath = path;
    notifyListeners();
    if (path == null) {
      await _prefs.remove(_kAvatar);
    } else {
      await _prefs.setString(_kAvatar, path);
    }
  }

  Future<void> setFreeThreshold(double value) async {
    _freeThreshold = value;
    notifyListeners();
    await _prefs.setDouble(_kFree, value);
  }

  Future<void> markSynced(DateTime when) async {
    _lastSync = when;
    notifyListeners();
    await _prefs.setString(_kLastSync, when.toIso8601String());
  }
}

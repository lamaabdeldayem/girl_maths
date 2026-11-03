// lib/core/formatters.dart
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class Fmt {
  Fmt(this.symbol, this.languageCode);

  final String symbol;
  final String languageCode;

  bool get _ar => languageCode == 'ar';

  String money(double value, {int decimals = 2}) {
    final number = NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: decimals,
    ).format(value);
    // EGP 1,250.00  |  1,250.00 ج.م
    return _ar ? '$number $symbol' : '$symbol $number';
  }

  String moneyShort(double value) {
    if (value.abs() < 1000) return money(value, decimals: 0);
    final number = NumberFormat.compact(locale: 'en').format(value);
    return _ar ? '$number $symbol' : '$symbol $number';
  }

  /// Number only, e.g. 1.2K (chart axes).
  String compact(double value) =>
      NumberFormat.compact(locale: 'en').format(value);

  String percent(double value) => '${value.abs().toStringAsFixed(0)}%';

  String day(DateTime d) => DateFormat('EEE, d MMM', languageCode).format(d);
  String shortDate(DateTime d) => DateFormat('d MMM', languageCode).format(d);
  String fullDate(DateTime d) => DateFormat('d MMM yyyy', languageCode).format(d);
  String month(DateTime d) => DateFormat('MMMM yyyy', languageCode).format(d);
  String monthShort(DateTime d) => DateFormat('MMM', languageCode).format(d);
  String dateTime(DateTime d) =>
      DateFormat('d MMM yyyy, HH:mm', languageCode).format(d);
}

extension FmtX on BuildContext {
  Fmt get fmt {
    final s = watch<SettingsProvider>();
    return Fmt(s.currencySymbol, s.languageCode);
  }

  Fmt get fmtRead {
    final s = read<SettingsProvider>();
    return Fmt(s.currencySymbol, s.languageCode);
  }
}

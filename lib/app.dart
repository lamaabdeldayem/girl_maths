// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/about_screen.dart';
import 'screens/expense_detail_screen.dart';
import 'screens/main_navigation.dart';

class MasroufiApp extends StatelessWidget {
  const MasroufiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Masroufi – Girl Maths',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,

      // Language (persisted in SharedPreferences). Arabic flips the whole
      // UI to right-to-left automatically.
      locale: settings.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Named routes (Lecture 5)
      initialRoute: MainNavigation.routeName,
      routes: {
        MainNavigation.routeName: (_) => const MainNavigation(),
        ExpenseDetailScreen.routeName: (_) => const ExpenseDetailScreen(),
        AboutScreen.routeName: (_) => const AboutScreen(),
      },
    );
  }
}

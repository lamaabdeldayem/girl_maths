// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/expense_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/settings_provider.dart';
import 'services/database_helper.dart';
import 'services/firebase_service.dart';
import 'services/sync_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Environment variables (Firebase URL). The app still works offline-only
  // if the file or the key is missing.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env not loaded – running without cloud backup ($e)');
  }
  await initializeDateFormatting();

  final settings = await SettingsProvider.create();
  final repo = SyncRepository(
    local: DatabaseHelper.instance,
    remote: FirebaseService(userId: settings.userId),
  );

  runApp(MasroufiRoot(settings: settings, repository: repo));
}

/// Wires the providers above the MaterialApp (Lecture 6: MultiProvider).
class MasroufiRoot extends StatelessWidget {
  const MasroufiRoot({
    super.key,
    required this.settings,
    required this.repository,
    this.autoLoad = true,
  });

  final SettingsProvider settings;
  final SyncRepository repository;
  final bool autoLoad;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider(
          create: (_) {
            final p = ExpenseProvider(repository, onSynced: settings.markSynced);
            if (autoLoad) p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final p = GoalsProvider(repository);
            if (autoLoad) p.init();
            return p;
          },
        ),
      ],
      child: const MasroufiApp(),
    );
  }
}

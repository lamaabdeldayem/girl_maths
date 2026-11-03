// lib/screens/settings_screen.dart
//
// Settings persisted with SharedPreferences: profile (name + photo), theme,
// language, currency, budget, girl-math threshold; Firebase sync status.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/responsive.dart';
import '../providers/expense_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/settings_provider.dart';
import '../services/image_storage.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'goals_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          MaxWidth(
            maxWidth: 1100,
            child: ResponsiveColumns(
              minItemWidth: 380,
              maxColumns: 2,
              children: [
                _ProfileSection(),
                _AppearanceSection(),
                _GirlMathSection(),
                _CloudSection(),
                _AboutSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatefulWidget {
  const _ProfileSection();

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
        text: context.read<SettingsProvider>().userName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final settings = context.read<SettingsProvider>();
    final path = await pickImage(context, prefix: 'avatar');
    if (path != null) {
      final old = settings.profileImagePath;
      await settings.setProfileImage(path);
      await ImageStorage.delete(old);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsProvider>();
    return SectionCard(
      emoji: '👑',
      title: s.profile,
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _changePhoto,
                child: const ProfileAvatar(radius: 46),
              ),
              PositionedDirectional(
                bottom: 0,
                end: 0,
                child: Material(
                  color: AppColors.hotPink,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _changePhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            settings.userName.isEmpty ? s.mainCharacter : settings.userName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (settings.profileImagePath != null)
            TextButton(
              onPressed: () async {
                final old = settings.profileImagePath;
                await settings.setProfileImage(null);
                await ImageStorage.delete(old);
              },
              child: Text(s.removePhoto),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: s.yourName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            onSubmitted: settings.setUserName,
            onTapOutside: (_) {
              FocusScope.of(context).unfocus();
              if (_name.text.trim() != settings.userName) {
                settings.setUserName(_name.text);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsProvider>();
    return SectionCard(
      emoji: '🎨',
      title: s.appearance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.theme, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(s.themeSystem)),
                ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(s.themeLight)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(s.themeDark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (v) => settings.setThemeMode(v.first),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.language, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'ar', label: Text('العربية')),
              ],
              selected: {settings.languageCode},
              onSelectionChanged: (v) => settings.setLanguage(v.first),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: settings.currency.code,
            decoration: InputDecoration(
              labelText: s.currency,
              prefixIcon: const Icon(Icons.currency_exchange),
            ),
            items: [
              for (final c in Currency.all)
                DropdownMenuItem(
                  value: c.code,
                  child: Text(
                      '${c.code}  (${settings.isArabic ? c.symbolAr : c.symbolEn})'),
                ),
            ],
            onChanged: (v) {
              if (v != null) settings.setCurrency(v);
            },
          ),
        ],
      ),
    );
  }
}

class _GirlMathSection extends StatelessWidget {
  const _GirlMathSection();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final settings = context.watch<SettingsProvider>();
    return SectionCard(
      emoji: '🎀',
      title: s.girlMath,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: Text(s.monthlyBudget),
            trailing: Text(fmt.money(settings.monthlyBudget, decimals: 0),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.hotPink)),
            onTap: () => editBudget(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.money_off_outlined),
            title: Text(s.freeThreshold),
            subtitle: Text(s.freeThresholdHelp),
            trailing: Text(fmt.money(settings.freeThreshold, decimals: 0),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.hotPink)),
            onTap: () async {
              final v = await askAmount(context,
                  title: s.freeThreshold, initial: settings.freeThreshold);
              if (v != null) await settings.setFreeThreshold(v);
            },
          ),
        ],
      ),
    );
  }
}

class _CloudSection extends StatelessWidget {
  const _CloudSection();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final settings = context.watch<SettingsProvider>();
    final expenses = context.watch<ExpenseProvider>();

    final String status;
    if (!expenses.hasBackend) {
      status = s.notConfigured;
    } else if (expenses.syncError != null) {
      status = s.offline;
    } else if (expenses.pendingCount > 0) {
      status = s.pendingChanges(expenses.pendingCount);
    } else {
      status = s.syncDone;
    }

    return SectionCard(
      emoji: '☁️',
      title: s.cloud,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(status),
          const SizedBox(height: 4),
          Text(
            settings.lastSync == null
                ? s.neverSynced
                : s.lastSynced(fmt.dateTime(settings.lastSync!)),
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: !expenses.hasBackend || expenses.isSyncing
                ? null
                : () async {
                    final goals = context.read<GoalsProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    await expenses.refresh();
                    await goals.refresh();
                    messenger.showSnackBar(SnackBar(
                      content: Text(
                          expenses.syncError == null ? s.syncDone : s.offline),
                    ));
                  },
            icon: expenses.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync),
            label: Text(expenses.isSyncing ? s.syncing : s.syncNow),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SectionCard(
      emoji: 'ℹ️',
      title: s.about,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(s.about),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AboutScreen.routeName),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_forever_outlined,
                color: AppColors.danger),
            title: Text(s.clearData,
                style: const TextStyle(color: AppColors.danger)),
            onTap: () async {
              final expenses = context.read<ExpenseProvider>();
              final goals = context.read<GoalsProvider>();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(s.dangerZone),
                  content: Text(s.clearDataConfirm),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(s.cancel)),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s.delete),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await expenses.clearLocal();
                goals.clearLocal();
              }
            },
          ),
        ],
      ),
    );
  }
}

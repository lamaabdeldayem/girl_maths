// lib/screens/goals_screen.dart
//
// Goals: the monthly budget + "wishlist" savings goals with photos.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/responsive.dart';
import '../models/monthly_summary.dart';
import '../models/savings_goal.dart';
import '../providers/expense_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/settings_provider.dart';
import '../services/image_storage.dart';
import '../widgets/common.dart';
import '../widgets/dashboard_cards.dart';

/// Dialog that asks for a positive amount.
Future<double?> askAmount(BuildContext context,
    {required String title, double? initial}) {
  final s = context.sRead;
  final symbol = context.read<SettingsProvider>().currencySymbol;
  final controller = TextEditingController(
      text: initial == null || initial == 0 ? '' : initial.toStringAsFixed(0));
  final formKey = GlobalKey<FormState>();
  return showDialog<double>(
    context: context,
    builder: (ctx) {
      void submit() {
        if (formKey.currentState!.validate()) {
          Navigator.pop(
              ctx, double.parse(controller.text.trim().replaceAll(',', '.')));
        }
      }

      return AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(suffixText: symbol),
            onFieldSubmitted: (_) => submit(),
            validator: (v) {
              final d = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
              return d == null || d <= 0 ? s.errAmount : null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(onPressed: submit, child: Text(s.save)),
        ],
      );
    },
  );
  // (controller is not disposed here on purpose: the dialog's closing
  // animation may still use it; it is garbage-collected afterwards)
}

Future<void> editBudget(BuildContext context) async {
  final settings = context.read<SettingsProvider>();
  final value = await askAmount(context,
      title: context.sRead.monthlyBudget, initial: settings.monthlyBudget);
  if (value != null) await settings.setMonthlyBudget(value);
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final goalsProvider = context.watch<GoalsProvider>();
    final settings = context.watch<SettingsProvider>();
    final month = context.watch<ExpenseProvider>().currentMonth;
    final now = DateTime.now();
    final daysLeft = daysInMonth(now) - now.day + 1;
    final remaining =
        (settings.monthlyBudget - month.total).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: Text(s.goalsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_goals',
        onPressed: () => showGoalForm(context),
        icon: const Icon(Icons.add),
        label: Text(s.addGoal),
      ),
      body: RefreshIndicator(
        onRefresh: goalsProvider.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            ResponsiveColumns(
              minItemWidth: 340,
              maxColumns: 2,
              children: [
                BudgetGoalCard(onEdit: () => editBudget(context)),
                SectionCard(
                  emoji: '🧮',
                  title: s.monthlyBudget,
                  trailing: TextButton.icon(
                    onPressed: () => editBudget(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(s.editBudget),
                  ),
                  child: Text(
                    s.dailyAllowance(fmt.money(remaining / daysLeft), daysLeft),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(s.wishlist,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                if (goalsProvider.goals.isNotEmpty)
                  Text(
                    s.saved(fmt.moneyShort(goalsProvider.totalSaved),
                        fmt.moneyShort(goalsProvider.totalTarget)),
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (goalsProvider.goals.isEmpty)
              EmptyState(
                message: s.noGoals,
                image: 'assets/images/empty_goals.png',
              )
            else
              ResponsiveColumns(
                minItemWidth: 300,
                maxColumns: 3,
                children: [
                  for (final g in goalsProvider.goals)
                    GoalCard(key: ValueKey(g.id), goal: g),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final perDay = goal.dailyNeeded(DateTime.now());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ImageStorage.exists(goal.imagePath))
            LocalImage(path: goal.imagePath, height: 140, radius: 0)
          else
            Container(
              height: 90,
              color: AppColors.hotPink.withValues(alpha: 0.10),
              alignment: Alignment.center,
              child: Text(goal.emoji, style: const TextStyle(fontSize: 44)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${goal.emoji} ${goal.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          showGoalForm(context, existing: goal);
                        } else if (v == 'delete') {
                          await context.read<GoalsProvider>().deleteGoal(goal.id);
                          await ImageStorage.delete(goal.imagePath);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(s.edit)),
                        PopupMenuItem(value: 'delete', child: Text(s.delete)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 10,
                    backgroundColor: AppColors.blush,
                    valueColor: AlwaysStoppedAnimation(
                        goal.isCompleted ? AppColors.success : AppColors.hotPink),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.saved(fmt.money(goal.savedAmount, decimals: 0), fmt.money(goal.targetAmount, decimals: 0))}'
                  '  •  ${(goal.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  goal.isCompleted
                      ? s.goalReached
                      : perDay != null
                          ? s.perDayToGoal(fmt.money(perDay))
                          : (goal.deadline == null ? s.noDeadline : ''),
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).hintColor),
                ),
                if (goal.deadline != null)
                  Text('⏳ ${fmt.fullDate(goal.deadline!)}',
                      style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 10),
                if (!goal.isCompleted)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final provider = context.read<GoalsProvider>();
                        final amount =
                            await askAmount(context, title: s.howMuchSaved);
                        if (amount != null) {
                          await provider.addMoney(goal, amount);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(s.addMoney),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Goal form (dialog; scrollable so it also fits a landscape phone)
// -----------------------------------------------------------------------------
Future<void> showGoalForm(BuildContext context, {SavingsGoal? existing}) {
  return showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _GoalForm(existing: existing),
      ),
    ),
  );
}

class _GoalForm extends StatefulWidget {
  const _GoalForm({this.existing});

  final SavingsGoal? existing;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  static const _emojis = ['👜', '👠', '💄', '✈️', '📱', '💍', '🎧', '🚗', '🏝️', '🎓'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _target;
  late String _emoji;
  DateTime? _deadline;
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _title = TextEditingController(text: g?.title ?? '');
    _target = TextEditingController(
        text: g == null ? '' : g.targetAmount.toStringAsFixed(0));
    _emoji = g?.emoji ?? _emojis.first;
    _deadline = g?.deadline;
    _imagePath = g?.imagePath;
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<GoalsProvider>();
    final navigator = Navigator.of(context);
    final target = double.parse(_target.text.trim().replaceAll(',', '.'));
    final old = widget.existing;
    final goal = old == null
        ? SavingsGoal(
            title: _title.text.trim(),
            emoji: _emoji,
            targetAmount: target,
            deadline: _deadline,
            imagePath: _imagePath,
          )
        : old.copyWith(
            title: _title.text.trim(),
            emoji: _emoji,
            targetAmount: target,
            deadline: _deadline,
            clearDeadline: _deadline == null,
            imagePath: _imagePath,
            clearImage: _imagePath == null,
          );
    await provider.saveGoal(goal);
    if (old?.imagePath != null && old!.imagePath != _imagePath) {
      await ImageStorage.delete(old.imagePath);
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final symbol = context.watch<SettingsProvider>().currencySymbol;

    return SingleChildScrollView(
      // (the Dialog itself already avoids the keyboard)
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? s.addGoal : s.editGoal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.hotPink),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                  labelText: s.goalTitle, hintText: s.goalTitleHint),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.errTitle : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _target,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: s.targetAmount, suffixText: symbol),
              validator: (v) {
                final d =
                    double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                return d == null || d <= 0 ? s.errAmount : null;
              },
            ),
            const SizedBox(height: 14),
            Text(s.emoji, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in _emojis)
                  ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 18)),
                    selected: e == _emoji,
                    onSelected: (_) => setState(() => _emoji = e),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_deadline == null
                        ? s.deadline
                        : fmt.fullDate(_deadline!)),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _deadline ?? now.add(const Duration(days: 30)),
                        firstDate: now,
                        lastDate: DateTime(now.year + 10),
                      );
                      if (picked != null) setState(() => _deadline = picked);
                    },
                  ),
                ),
                if (_deadline != null)
                  IconButton(
                    onPressed: () => setState(() => _deadline = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (ImageStorage.exists(_imagePath)) ...[
                  LocalImage(
                      path: _imagePath, width: 56, height: 56, radius: 12),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(s.changePhoto),
                    onPressed: () async {
                      final path = await pickImage(context, prefix: 'goal');
                      if (path != null) setState(() => _imagePath = path);
                    },
                  ),
                ),
                if (_imagePath != null)
                  IconButton(
                    onPressed: () => setState(() => _imagePath = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.cancel)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text(s.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

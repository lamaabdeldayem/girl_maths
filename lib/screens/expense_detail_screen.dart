// lib/screens/expense_detail_screen.dart
//
// Reached with Navigator.pushNamed(context, ExpenseDetailScreen.routeName,
// arguments: expenseId) on phones; embedded as the "detail" pane of the
// master/detail layout on large screens.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/responsive.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/image_storage.dart';
import '../widgets/common.dart';
import '../widgets/expense_form.dart';
import '../widgets/expense_tile.dart';
import 'main_navigation.dart';

/// Large screens show the list and the details side by side.
bool useMasterDetail(BuildContext context) => context.screenSize.width >= 1000;

/// Opens an expense: detail pane on big screens, a new route on phones.
void openExpense(BuildContext context, Expense e, {bool fromHome = false}) {
  final provider = context.read<ExpenseProvider>();
  if (useMasterDetail(context)) {
    provider.selectExpense(e.id);
    if (fromHome) {
      provider.setMonth(e.date);
      MainNavigation.goTo(context, MainNavigation.expenses);
    }
  } else {
    Navigator.pushNamed(context, ExpenseDetailScreen.routeName,
        arguments: e.id);
  }
}

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key});

  static const routeName = '/expense-detail';

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    final expense = context.watch<ExpenseProvider>().byId(id);
    final s = context.s;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.expenseDetails),
        actions: expense == null
            ? null
            : [
                IconButton(
                  tooltip: s.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showExpenseForm(context, existing: expense),
                ),
                IconButton(
                  tooltip: s.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => confirmAndDelete(context, expense, popRoute: true),
                ),
              ],
      ),
      body: expense == null
          ? const Center(child: Text('🤷‍♀️', style: TextStyle(fontSize: 48)))
          : ExpenseDetailView(expense: expense),
    );
  }
}

Future<void> confirmAndDelete(BuildContext context, Expense expense,
    {bool popRoute = false}) async {
  final s = context.sRead;
  final provider = context.read<ExpenseProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.deleteConfirm),
      content: Text(s.deleteConfirmBody),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s.delete),
        ),
      ],
    ),
  );
  if (ok != true) return;
  if (popRoute) navigator.pop();
  await deleteWithUndoUsing(
      provider: provider, messenger: messenger, s: s, expense: expense);
}

class ExpenseDetailView extends StatelessWidget {
  const ExpenseDetailView({super.key, required this.expense, this.embedded = false});

  final Expense expense;

  /// true inside the master/detail pane (shows its own edit/delete buttons).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final settings = context.watch<SettingsProvider>();
    final ar = settings.isArabic;
    final cat = expense.category;
    final hasImage = ImageStorage.exists(expense.imagePath);

    final header = Column(
      children: [
        CategoryBadge(category: cat, size: 76),
        const SizedBox(height: 14),
        Text(
          expense.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          '-${fmt.money(expense.amount)}',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: AppColors.hotPink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '“${cat.id == 'fashion' ? s.costPerWear(fmt.money(expense.amount / 30)) : cat.justification(ar)}”',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontStyle: FontStyle.italic, color: Theme.of(context).hintColor),
        ),
      ],
    );

    final info = Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(s.category),
            trailing: Text('${cat.emoji} ${cat.label(ar)}'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(s.date),
            trailing: Text(fmt.fullDate(expense.date)),
          ),
          if (expense.note != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: Text(expense.note!),
            ),
          ],
          if (context.select<ExpenseProvider, bool>((p) => p.hasBackend)) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(expense.isSynced
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_upload_outlined),
              title: Text(expense.isSynced ? s.syncDone : s.pendingSync),
            ),
          ],
        ],
      ),
    );

    final image = hasImage
        ? GestureDetector(
            onTap: () => _openFullImage(context, expense.imagePath!),
            child: Hero(
              tag: 'img_${expense.id}',
              child: LocalImage(path: expense.imagePath, height: 260, width: double.infinity),
            ),
          )
        : null;

    final actions = embedded
        ? Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showExpenseForm(context, existing: expense),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(s.edit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger),
                  onPressed: () => confirmAndDelete(context, expense),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(s.delete),
                ),
              ),
            ],
          )
        : null;

    return LayoutBuilder(builder: (context, c) {
      // Landscape / wide: header + photo on one side, details on the other.
      if (c.maxWidth >= 640) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(children: [
                  header,
                  if (image != null) ...[const SizedBox(height: 16), image],
                ]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(children: [
                  info,
                  if (actions != null) ...[const SizedBox(height: 16), actions],
                ]),
              ),
            ],
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          header,
          const SizedBox(height: 20),
          if (image != null) ...[image, const SizedBox(height: 16)],
          info,
          if (actions != null) ...[const SizedBox(height: 16), actions],
        ],
      );
    });
  }

  void _openFullImage(BuildContext context, String path) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Hero(
              tag: 'img_${expense.id}',
              child: LocalImage(path: path, fit: BoxFit.contain, radius: 0),
            ),
          ),
        ),
      ),
    ));
  }
}

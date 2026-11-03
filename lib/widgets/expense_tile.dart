// lib/widgets/expense_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/image_storage.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
    this.selected = false,
    this.showDate = true,
  });

  final Expense expense;
  final VoidCallback? onTap;
  final bool selected;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    final ar = context.watch<SettingsProvider>().isArabic;
    final cat = expense.category;
    final subtitle = showDate
        ? '${cat.label(ar)} • ${fmt.shortDate(expense.date)}'
        : cat.label(ar);

    return Card(
      color: selected ? AppColors.hotPink.withValues(alpha: 0.10) : null,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cat.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(cat.emoji, style: const TextStyle(fontSize: 19)),
        ),
        title: Text(
          expense.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(subtitle,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            if (expense.imagePath != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.photo_outlined, size: 14),
            ],
            if (!expense.isSynced &&
                context.select<ExpenseProvider, bool>((p) => p.hasBackend)) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: context.s.pendingSync,
                child: const Icon(Icons.cloud_upload_outlined, size: 14),
              ),
            ],
          ],
        ),
        trailing: Text(
          '-${fmt.money(expense.amount)}',
          style: const TextStyle(
            color: AppColors.hotPink,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// Swipe-to-delete wrapper (Lecture 6) with an Undo snackbar.
class DismissibleExpense extends StatelessWidget {
  const DismissibleExpense({super.key, required this.expense, required this.child});

  final Expense expense;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Dismissible(
      key: ValueKey('dismiss_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: rtl ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => deleteWithUndo(context, expense),
      child: child,
    );
  }
}

/// Deletes an expense and shows "Undo". The photo file is only removed once
/// the snackbar closes without undo.
Future<void> deleteWithUndo(BuildContext context, Expense expense) =>
    deleteWithUndoUsing(
      provider: context.read<ExpenseProvider>(),
      messenger: ScaffoldMessenger.of(context),
      s: context.sRead,
      expense: expense,
    );

/// Same as [deleteWithUndo] but usable after the calling screen was popped.
Future<void> deleteWithUndoUsing({
  required ExpenseProvider provider,
  required ScaffoldMessengerState messenger,
  required S s,
  required Expense expense,
}) async {
  await provider.removeExpense(expense.id);
  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text('${s.deleted}: ${expense.title}'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: s.undo,
        onPressed: () => provider.restoreExpense(expense),
      ),
    ),
  );
  final reason = await controller.closed;
  if (reason != SnackBarClosedReason.action) {
    await ImageStorage.delete(expense.imagePath);
  }
}

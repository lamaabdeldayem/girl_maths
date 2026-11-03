// lib/screens/expenses_screen.dart
//
// All expenses of the selected month, grouped by day, with search, category
// filter, swipe-to-delete (+undo) and pull-to-refresh.
// Large screens: master/detail (list + details side by side).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/responsive.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common.dart';
import '../widgets/expense_form.dart';
import '../widgets/expense_tile.dart';
import 'expense_detail_screen.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final provider = context.watch<ExpenseProvider>();
    final masterDetail = useMasterDetail(context);
    final selected = provider.byId(provider.selectedExpenseId);

    final list = _ExpenseList(masterDetail: masterDetail);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navExpenses),
        actions: const [SyncStatusChip()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_expenses',
        tooltip: s.addExpense,
        onPressed: () => showExpenseForm(context),
        child: const Icon(Icons.add),
      ),
      body: masterDetail
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 440, child: list),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selected == null
                      ? Center(
                          child: EmptyState(
                            message: s.selectExpense,
                            image: 'assets/images/logo.png',
                          ),
                        )
                      : ExpenseDetailView(
                          key: ValueKey(selected.id),
                          expense: selected,
                          embedded: true,
                        ),
                ),
              ],
            )
          : MaxWidth(maxWidth: 760, child: list),
    );
  }
}

class _ExpenseList extends StatefulWidget {
  const _ExpenseList({required this.masterDetail});

  final bool masterDetail;

  @override
  State<_ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<_ExpenseList> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    // the query lives in the provider so it survives rotation
    _search = TextEditingController(
        text: context.read<ExpenseProvider>().query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _dayLabel(S s, Fmt fmt, DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return s.today;
    if (day == today.subtract(const Duration(days: 1))) return s.yesterday;
    return fmt.day(d);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final ar = context.watch<SettingsProvider>().isArabic;
    final provider = context.watch<ExpenseProvider>();
    final items = provider.filteredExpenses;
    final monthTotal = items.fold(0.0, (sum, e) => sum + e.amount);

    // Group by calendar day (items are already newest first)
    final groups = <DateTime, List<Expense>>{};
    for (final e in items) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      groups.putIfAbsent(key, () => []).add(e);
    }

    final header = Column(
      children: [
        MonthSelector(label: fmt.month(provider.selectedMonth)),
        Text(
          fmt.money(monthTotal),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.hotPink,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: provider.setQuery,
          decoration: InputDecoration(
            hintText: s.searchHint,
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            suffixIcon: provider.query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      provider.setQuery('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(s.all),
                  selected: provider.categoryFilter == null,
                  onSelected: (_) => provider.setCategoryFilter(null),
                ),
              ),
              for (final c in ExpenseCategory.all)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text('${c.emoji} ${c.label(ar)}'),
                    selected: provider.categoryFilter == c.id,
                    selectedColor: c.color.withValues(alpha: 0.25),
                    onSelected: (sel) =>
                        provider.setCategoryFilter(sel ? c.id : null),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );

    final children = <Widget>[header];
    if (items.isEmpty) {
      children.add(EmptyState(
        message: provider.query.isNotEmpty || provider.categoryFilter != null
            ? s.noResults
            : s.noExpenses,
      ));
    } else {
      groups.forEach((day, list) {
        final dayTotal = list.fold(0.0, (sum, e) => sum + e.amount);
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _dayLabel(s, fmt, day),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(fmt.money(dayTotal),
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ));
        for (final e in list) {
          children.add(Padding(
            key: ValueKey(e.id),
            padding: const EdgeInsets.only(bottom: 8),
            child: DismissibleExpense(
              expense: e,
              child: ExpenseTile(
                expense: e,
                showDate: false,
                selected:
                    widget.masterDetail && provider.selectedExpenseId == e.id,
                onTap: () => openExpense(context, e),
              ),
            ),
          ));
        }
      });
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: children,
      ),
    );
  }
}

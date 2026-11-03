// lib/widgets/expense_form.dart
//
// Add / edit expense form. Opens as a bottom sheet on phones in portrait and
// as a centred dialog on wide screens / landscape (Lecture 4: responsive +
// keyboard-safe bottom sheet).
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
import '../services/image_storage.dart';
import 'common.dart';

Future<void> showExpenseForm(BuildContext context, {Expense? existing}) {
  final usesSheet = context.isCompact && !context.isLandscape;
  if (usesSheet) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ExpenseForm(existing: existing),
    );
  }
  return showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ExpenseForm(existing: existing, inDialog: true),
      ),
    ),
  );
}

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key, this.existing, this.inDialog = false});

  final Expense? existing;
  final bool inDialog;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _categoryId;
  String? _imagePath;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e == null ? '' : _trimZeros(e.amount),
    );
    _noteController = TextEditingController(text: e?.note ?? '');
    _selectedDate = e?.date ?? DateTime.now();
    _categoryId = e?.categoryId ?? ExpenseCategory.all.first.id;
    _imagePath = e?.imagePath;
    _amountController.addListener(() => setState(() {}));
  }

  static String _trimZeros(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickPhoto() async {
    final path = await pickImage(context, prefix: 'receipt');
    if (path != null) {
      // replacing an unsaved photo -> clean up the old file
      if (_imagePath != null && _imagePath != widget.existing?.imagePath) {
        await ImageStorage.delete(_imagePath);
      }
      setState(() => _imagePath = path);
    }
  }

  double? _parseAmount(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final provider = context.read<ExpenseProvider>();
    final navigator = Navigator.of(context);
    final note = _noteController.text.trim();
    final expense = Expense(
      id: widget.existing?.id,
      title: _titleController.text.trim(),
      amount: _parseAmount(_amountController.text)!,
      date: _selectedDate,
      categoryId: _categoryId,
      note: note.isEmpty ? null : note,
      imagePath: _imagePath,
    );

    try {
      if (_isEdit) {
        await provider.updateExpense(expense);
        // photo replaced/removed -> delete the old file
        final old = widget.existing!.imagePath;
        if (old != null && old != _imagePath) await ImageStorage.delete(old);
      } else {
        await provider.addExpense(expense);
      }
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final s = context.sRead;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.errorTitle),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.ok)),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fmt = context.fmt;
    final settings = context.watch<SettingsProvider>();
    final ar = settings.isArabic;
    final category = ExpenseCategory.byId(_categoryId);
    final amount = _parseAmount(_amountController.text) ?? 0;

    final title = TextFormField(
      key: const Key('titleField'),
      controller: _titleController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: s.whatDidYouBuy,
        hintText: s.titleHint,
        prefixIcon: const Icon(Icons.shopping_bag_outlined),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? s.errTitle : null,
    );

    final amountField = TextFormField(
      key: const Key('amountField'),
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: s.amount,
        prefixIcon: const Icon(Icons.payments_outlined),
        suffixText: settings.currencySymbol,
      ),
      validator: (v) {
        final value = _parseAmount(v ?? '');
        return (value == null || value <= 0) ? s.errAmount : null;
      },
    );

    final dateRow = InkWell(
      onTap: _presentDatePicker,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: s.date,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(fmt.fullDate(_selectedDate)),
      ),
    );

    final noteField = TextFormField(
      controller: _noteController,
      maxLines: 2,
      minLines: 1,
      decoration: InputDecoration(
        labelText: s.note,
        prefixIcon: const Icon(Icons.sticky_note_2_outlined),
      ),
    );

    final categories = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in ExpenseCategory.all)
          ChoiceChip(
            label: Text('${c.emoji} ${c.label(ar)}'),
            selected: c.id == _categoryId,
            selectedColor: c.color.withValues(alpha: 0.25),
            onSelected: (_) => setState(() => _categoryId = c.id),
          ),
      ],
    );

    final justificationText = category.id == 'fashion' && amount > 0
        ? s.costPerWear(fmt.money(amount / 30))
        : category.justification(ar);

    final photo = Row(
      children: [
        if (ImageStorage.exists(_imagePath)) ...[
          LocalImage(path: _imagePath, width: 64, height: 64, radius: 12),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(s.photo, overflow: TextOverflow.ellipsis),
          ),
        ),
        if (_imagePath != null)
          IconButton(
            tooltip: s.removePhoto,
            onPressed: () => setState(() => _imagePath = null),
            icon: const Icon(Icons.close),
          ),
      ],
    );

    final submit = FilledButton(
      key: const Key('submitExpense'),
      onPressed: _isSaving ? null : _submit,
      child: _isSaving
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            )
          : Text(_isEdit ? s.saveChanges : s.justifyExpense),
    );

    return Padding(
      // keeps the fields above the keyboard (Lecture 4). A Dialog already
      // moves itself out of the keyboard's way, so only the sheet needs it.
      padding: EdgeInsets.only(
        bottom: widget.inDialog ? 0 : MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, widget.inDialog ? 24 : 4, 20, 24),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(builder: (context, constraints) {
            // Two columns when the form is wide enough (tablet / landscape).
            final twoCols = constraints.maxWidth >= 520;
            const gap = SizedBox(height: 14, width: 14);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEdit ? s.editPurchase : s.logNewPurchase,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.hotPink,
                  ),
                ),
                const SizedBox(height: 18),
                if (twoCols)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: title),
                      gap,
                      Expanded(flex: 2, child: amountField),
                    ],
                  )
                else ...[
                  title,
                  gap,
                  amountField,
                ],
                gap,
                Text(s.justification,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                categories,
                const SizedBox(height: 6),
                Text(
                  '“$justificationText”',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                gap,
                if (twoCols)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: dateRow),
                      gap,
                      Expanded(child: noteField),
                    ],
                  )
                else ...[
                  dateRow,
                  gap,
                  noteField,
                ],
                gap,
                photo,
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (widget.inDialog) ...[
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(s.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(flex: 2, child: submit),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

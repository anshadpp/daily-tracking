import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/tracker_provider.dart';
import '../services/settings_service.dart';
import '../widgets/glass.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _date = DateTime.now();
  late Future<_ExpensesBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  String _ds(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<_ExpensesBundle> _load() async {
    final expenses = await AppDatabase.instance.getExpensesForDate(_ds(_date));
    final monthTotal = await AppDatabase.instance.getMonthTotalCents(_date);
    final daily = await AppDatabase.instance.getDailyExpenseTotals(7);
    return _ExpensesBundle(
        expenses: expenses, monthTotalCents: monthTotal, daily: daily);
  }

  void _reload() => setState(() => _future = _load());

  void _shift(int days) {
    setState(() {
      _date = _date.add(Duration(days: days));
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    final cats = tp.categoryById;
    final currency = AppSettings.I.currencySymbol;
    final isToday = _sameDay(_date, DateTime.now());

    return Scaffold(
      body: FutureBuilder<_ExpensesBundle>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final b = snap.data!;
          final dailyTotal = b.expenses.fold<int>(
              0, (sum, e) => sum + e.amountCents);

          return SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 120),
              children: [
                _DateHeader(
                  date: _date,
                  isToday: isToday,
                  onPrev: () => _shift(-1),
                  onNext: isToday ? null : () => _shift(1),
                  onTapToday: () => setState(() {
                    _date = DateTime.now();
                    _future = _load();
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Today',
                          amount:
                              '$currency${(dailyTotal / 100).toStringAsFixed(0)}',
                          subtitle: '${b.expenses.length} items',
                          highlighted: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryTile(
                          label: 'This month',
                          amount:
                              '$currency${(b.monthTotalCents / 100).toStringAsFixed(0)}',
                          subtitle: DateFormat('MMMM').format(_date),
                        ),
                      ),
                    ],
                  ),
                ),
                _Last7Chart(daily: b.daily, currency: currency),
                const SizedBox(height: 8),
                if (b.expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                    child: Center(
                      child: Text(
                        isToday
                            ? 'No expenses yet.\nTap + to log one.'
                            : 'No expenses on this day.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color:
                                Theme.of(ctx).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                for (final e in b.expenses)
                  _ExpenseCard(
                    expense: e,
                    category: cats[e.categoryId],
                    currency: currency,
                    onEdit: () => _editSheet(ctx, existing: e),
                    onDelete: () async {
                      await AppDatabase.instance.deleteExpense(e.id!);
                      _reload();
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _editSheet(BuildContext context, {Expense? existing}) async {
    final tp = context.read<TrackerProvider>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final amountCtrl = TextEditingController(
        text: existing == null
            ? ''
            : (existing.amountCents / 100).toStringAsFixed(
                existing.amountCents % 100 == 0 ? 0 : 2));
    final noteCtrl = TextEditingController(text: existing?.description ?? '');
    int categoryId = existing?.categoryId ??
        (tp.categories.isNotEmpty ? tp.categories.first.id! : 1);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          ),
          child: Glass(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'New expense' : 'Edit expense',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    autofocus: existing == null,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      labelText: 'Amount (${AppSettings.I.currencySymbol})',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'What for?',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in tp.categories)
                        _CatChip(
                          category: c,
                          selected: c.id == categoryId,
                          onTap: () =>
                              setState(() => categoryId = c.id!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (existing != null)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              await AppDatabase.instance
                                  .deleteExpense(existing.id!);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _reload();
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
                            label: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () async {
                            final amt =
                                double.tryParse(amountCtrl.text.trim());
                            if (amt == null || amt <= 0) return;
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) return;
                            final now = DateTime.now();
                            final newExp = (existing ??
                                    Expense(
                                      date: _ds(_date),
                                      amountCents: 0,
                                      title: '',
                                      categoryId: categoryId,
                                    ))
                                .copyWith(
                              amountCents: (amt * 100).round(),
                              title: title,
                              description: noteCtrl.text.trim().isEmpty
                                  ? null
                                  : noteCtrl.text.trim(),
                              categoryId: categoryId,
                              minutesOfDay: existing?.minutesOfDay ??
                                  (now.hour * 60 + now.minute),
                            );
                            if (existing == null) {
                              await AppDatabase.instance
                                  .insertExpense(newExp);
                            } else {
                              await AppDatabase.instance
                                  .updateExpense(newExp);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _reload();
                          },
                          child: Text(existing == null ? 'Save' : 'Update'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpensesBundle {
  final List<Expense> expenses;
  final int monthTotalCents;
  final List<DailyExpense> daily;
  _ExpensesBundle(
      {required this.expenses,
      required this.monthTotalCents,
      required this.daily});
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTapToday;
  const _DateHeader({
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onTapToday,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          InkWell(
            onTap: onPrev,
            borderRadius: BorderRadius.circular(999),
            child: Glass(
              borderRadius: BorderRadius.circular(999),
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.chevron_left_rounded, size: 20),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTapToday,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Text(
                      isToday ? 'TODAY' : 'JUMP TO TODAY',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, d MMM').format(date),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: onNext ?? () {},
            borderRadius: BorderRadius.circular(999),
            child: Glass(
              borderRadius: BorderRadius.circular(999),
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.chevron_right_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String amount;
  final String subtitle;
  final bool highlighted;
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.subtitle,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: highlighted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Last7Chart extends StatelessWidget {
  final List<DailyExpense> daily;
  final String currency;
  const _Last7Chart({required this.daily, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const SizedBox();
    final max = daily.map((d) => d.amountCents).fold<int>(
        0, (p, c) => c > p ? c : p);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Glass(
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'LAST 7 DAYS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Max $currency${(max / 100).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in daily)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            height: max == 0
                                ? 4
                                : (56 * (d.amountCents / max)).clamp(4, 56),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  cs.primary,
                                  cs.primary.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('E').format(d.date)[0],
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final AppCategory? category;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ExpenseCard({
    required this.expense,
    required this.category,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = category?.color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Dismissible(
        key: ValueKey('exp_${expense.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.red),
        ),
        onDismissed: (_) => onDelete(),
        child: GestureDetector(
          onTap: onEdit,
          child: Glass(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      color.withOpacity(0.35),
                      color.withOpacity(0.15),
                    ]),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Icon(
                      category?.icon ?? Icons.payments_rounded,
                      color: color,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (category != null) category!.name,
                          if (expense.minutesOfDay != null)
                            _fmt(expense.minutesOfDay!),
                          if (expense.description?.isNotEmpty ?? false)
                            expense.description!,
                        ].join('  •  '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currency${(expense.amountCents / 100).toStringAsFixed(expense.amountCents % 100 == 0 ? 0 : 2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int m) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }
}

class _CatChip extends StatelessWidget {
  final AppCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? category.color.withOpacity(0.22)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? category.color
                : Theme.of(context).colorScheme.outline.withOpacity(0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: category.color, size: 16),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                color: selected
                    ? category.color
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

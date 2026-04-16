import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database.dart';
import '../models/qada.dart';
import '../providers/tracker_provider.dart';
import '../widgets/glass.dart';

class QadaScreen extends StatefulWidget {
  const QadaScreen({super.key});
  @override
  State<QadaScreen> createState() => _QadaScreenState();
}

class _QadaScreenState extends State<QadaScreen> {
  late DateTime _month;
  Future<_QadaBundle>? _future;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _future = _load();
  }

  Future<_QadaBundle> _load() async {
    final calendar = await AppDatabase.instance
        .getPrayerCalendar(_month.year, _month.month);
    final stats = await AppDatabase.instance.getQadaStats();
    return _QadaBundle(calendar: calendar, stats: stats);
  }

  Future<void> _addBulkQada(
      BuildContext context, TrackerProvider tp) async {
    DateTime? from;
    DateTime? to;
    final selected = <String>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
                  Text('Bulk add missed prayers',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          )),
                  const SizedBox(height: 4),
                  Text(
                      'Select a date range and the same prayers will be added for every day.',
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: from ??
                                  DateTime.now()
                                      .subtract(const Duration(days: 30)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setSheet(() => from = d);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(from == null
                              ? 'From date'
                              : DateFormat('d MMM yy').format(from!)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: to ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setSheet(() => to = d);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(to == null
                              ? 'To date'
                              : DateFormat('d MMM yy').format(to!)),
                        ),
                      ),
                    ],
                  ),
                  if (from != null && to != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${to!.difference(from!).inDays + 1} days selected',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final p in [
                        'fajr',
                        'dhuhr',
                        'asr',
                        'maghrib',
                        'isha'
                      ])
                        FilterChip(
                          label: Text(
                              p[0].toUpperCase() + p.substring(1)),
                          avatar:
                              const Icon(Icons.mosque_rounded, size: 16),
                          selected: selected.contains(p),
                          onSelected: (v) => setSheet(() {
                            v ? selected.add(p) : selected.remove(p);
                          }),
                        ),
                      _SelectAllChip(
                        allSelected: selected.length == 5,
                        onTap: () => setSheet(() {
                          if (selected.length == 5) {
                            selected.clear();
                          } else {
                            selected.addAll([
                              'fajr',
                              'dhuhr',
                              'asr',
                              'maghrib',
                              'isha'
                            ]);
                          }
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (from == null ||
                              to == null ||
                              selected.isEmpty ||
                              to!.isBefore(from!))
                          ? null
                          : () {
                              final days =
                                  to!.difference(from!).inDays + 1;
                              tp.addBulkQada(
                                  from!, to!, selected.toList());
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                      'Added ${selected.length * days} Qada ($days days × ${selected.length} prayers)'),
                                ),
                              );
                            },
                      child: Text(
                          'Add ${selected.length} prayers × ${from != null && to != null ? to!.difference(from!).inDays + 1 : 0} days'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    setState(() => _future = _load());
  }

  void _shiftMonth(int d) {
    setState(() {
      _month = DateTime(_month.year, _month.month + d);
      _future = _load();
    });
  }

  Future<void> _addManualQada(
      BuildContext context, TrackerProvider tp) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return;

    final selected = <String>{};
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Glass(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Missed prayers — ${DateFormat('d MMM yyyy').format(date)}',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text('Select which prayers you missed on this day.',
                  style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final p in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
                    FilterChip(
                      label: Text(
                          p[0].toUpperCase() + p.substring(1)),
                      avatar: const Icon(Icons.mosque_rounded, size: 16),
                      selected: selected.contains(p),
                      onSelected: (v) => setSheet(() {
                        if (v) {
                          selected.add(p);
                        } else {
                          selected.remove(p);
                        }
                      }),
                    ),
                  _SelectAllChip(
                    allSelected: selected.length == 5,
                    onTap: () => setSheet(() {
                      if (selected.length == 5) {
                        selected.clear();
                      } else {
                        selected.addAll(
                            ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          tp.addManualQada(date, selected.toList());
                          Navigator.pop(ctx);
                        },
                  child: Text('Add ${selected.length} Qada'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Qada & Prayer Calendar')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'bulk',
              onPressed: () => _addBulkQada(context, tp),
              child: const Icon(Icons.date_range_rounded),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              heroTag: 'single',
              onPressed: () => _addManualQada(context, tp),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add missed'),
            ),
          ],
        ),
      ),
      body: FutureBuilder<_QadaBundle>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final b = snap.data!;
          final pending = b.stats['total_pending'] ?? 0;
          final madeUp = b.stats['total_made_up'] ?? 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              // Qada Counter Hero
              _QadaCounter(
                pending: pending,
                madeUp: madeUp,
                stats: b.stats,
              ),
              const SizedBox(height: 16),
              // Calendar
              _PrayerCalendar(
                month: _month,
                data: b.calendar,
                onPrev: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
              ),
              const SizedBox(height: 16),
              // Pending Qada list
              if (tp.pendingQada.isNotEmpty) ...[
                _PendingQadaList(
                  qadaList: tp.pendingQada,
                  onMarkDone: (q) async {
                    await tp.markQadaDone(q);
                    setState(() => _future = _load());
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                            '${q.prayerLabel} (${q.missedDate}) marked as made up'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () async {
                            await tp.undoQadaMadeUp(q);
                            setState(() => _future = _load());
                          },
                        ),
                      ),
                    );
                  },
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 48, color: cs.primary.withOpacity(0.6)),
                        const SizedBox(height: 12),
                        Text('No pending Qada',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: cs.primary)),
                        const SizedBox(height: 4),
                        Text('All prayers are up to date.',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QadaBundle {
  final Map<String, Map<String, String>> calendar; // date → {prayer: status}
  final Map<String, int> stats;
  _QadaBundle({required this.calendar, required this.stats});
}

class _QadaCounter extends StatelessWidget {
  final int pending;
  final int madeUp;
  final Map<String, int> stats;
  const _QadaCounter(
      {required this.pending, required this.madeUp, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final labels = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    return Glass(
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(20),
      tint: pending > 0 ? Colors.red.withOpacity(0.06) : null,
      child: Column(
        children: [
          Row(
            children: [
              // Big pending number
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$pending',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        color: pending > 0 ? Colors.red.shade400 : cs.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PENDING QADA',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: pending > 0
                            ? Colors.red.shade300
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: cs.outline.withOpacity(0.2),
              ),
              // Made up
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$madeUp',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        color: cs.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MADE UP',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 16),
            // Per-prayer breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < 5; i++)
                  _PrayerMiniStat(
                    label: labels[i],
                    count: stats[prayers[i]] ?? 0,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PrayerMiniStat extends StatelessWidget {
  final String label;
  final int count;
  const _PrayerMiniStat({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: count > 0 ? Colors.red.shade400 : cs.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PrayerCalendar extends StatelessWidget {
  final DateTime month;
  final Map<String, Map<String, String>> data;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _PrayerCalendar({
    required this.month,
    required this.data,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday =
        DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final today = DateTime.now();

    return Glass(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month header
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(month),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day headers
          Row(
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            )),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Calendar grid
          ...List.generate(_totalRows(firstWeekday, daysInMonth), (row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final dayNum =
                      row * 7 + col - (firstWeekday - 2);
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }
                  final date = DateTime(month.year, month.month, dayNum);
                  final ds =
                      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  final prayers = data[ds]; // null if no data
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;

                  return Expanded(
                    child: _CalendarCell(
                      day: dayNum,
                      prayers: prayers,
                      isToday: isToday,
                      isFuture: date.isAfter(today),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 10),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: const Color(0xFF2E7D32), label: 'Done'),
              const SizedBox(width: 10),
              _LegendDot(color: Colors.orange, label: 'Made up'),
              const SizedBox(width: 10),
              _LegendDot(color: Colors.red, label: 'Missed'),
              const SizedBox(width: 10),
              _LegendDot(
                  color: Colors.grey.withOpacity(0.4), label: 'No data'),
            ],
          ),
        ],
      ),
    );
  }

  int _totalRows(int firstWeekday, int daysInMonth) {
    final offset = firstWeekday - 1; // Mon=0 offset
    return ((offset + daysInMonth + 6) / 7).floor();
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final Map<String, String>? prayers; // prayer → 'done'|'missed'|'madeup'
  final bool isToday;
  final bool isFuture;
  const _CalendarCell({
    required this.day,
    required this.prayers,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final hasPrayers = prayers != null && prayers!.isNotEmpty;
    final doneCount = hasPrayers
        ? prayers!.values
            .where((v) => v == 'done' || v == 'madeup')
            .length
        : 0;
    final onTimeCount = hasPrayers
        ? prayers!.values.where((v) => v == 'done').length
        : 0;

    Color bgColor;
    if (isFuture) {
      bgColor = Colors.transparent;
    } else if (!hasPrayers) {
      bgColor = cs.surfaceContainerHighest.withOpacity(0.3);
    } else if (onTimeCount == 5) {
      bgColor = const Color(0xFF2E7D32).withOpacity(0.18);
    } else if (doneCount == 5) {
      bgColor = Colors.orange.withOpacity(0.12); // all done via qada
    } else if (doneCount > 0) {
      bgColor = Colors.orange.withOpacity(0.10);
    } else {
      bgColor = Colors.red.withOpacity(0.12);
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: isToday
            ? Border.all(color: cs.primary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
              color: isFuture
                  ? cs.onSurfaceVariant.withOpacity(0.4)
                  : cs.onSurface,
            ),
          ),
          if (hasPrayers && !isFuture) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: prayerKeys.map((p) {
                final s = prayers?[p];
                final color = s == null
                    ? Colors.grey.withOpacity(0.3)
                    : s == 'done'
                        ? const Color(0xFF2E7D32)
                        : s == 'madeup'
                            ? Colors.orange
                            : Colors.red;
                return Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
      ],
    );
  }
}

class _PendingQadaList extends StatelessWidget {
  final List<Qada> qadaList;
  final void Function(Qada) onMarkDone;
  const _PendingQadaList(
      {required this.qadaList, required this.onMarkDone});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Qada>>{};
    for (final q in qadaList) {
      grouped.putIfAbsent(q.missedDate, () => []).add(q);
    }
    return Glass(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Pending Qada',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a prayer to mark as made up.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final entry in grouped.entries) ...[
            Text(
              _formatDate(entry.key),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: entry.value.map((q) {
                return ActionChip(
                  label: Text(q.prayerLabel),
                  avatar: Icon(Icons.mosque_rounded,
                      size: 16, color: Colors.red.shade400),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  onPressed: () => onMarkDone(q),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  String _formatDate(String ds) {
    try {
      final d = DateTime.parse(ds);
      return DateFormat('EEE, d MMM yyyy').format(d);
    } catch (_) {
      return ds;
    }
  }
}

class _SelectAllChip extends StatelessWidget {
  final bool allSelected;
  final VoidCallback onTap;
  const _SelectAllChip({required this.allSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(allSelected ? 'Deselect all' : 'Select all'),
      avatar: Icon(
        allSelected
            ? Icons.deselect_rounded
            : Icons.select_all_rounded,
        size: 16,
      ),
      onPressed: onTap,
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/block.dart';
import '../models/category.dart';
import '../models/prayer.dart';
import '../models/qada.dart';
import '../models/todo.dart';
import '../providers/tracker_provider.dart';
import '../services/settings_service.dart';
import '../widgets/block_card.dart';
import '../widgets/glass.dart';
import 'qada_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    final isToday = _sameDay(tp.selectedDate, DateTime.now());
    final current = isToday ? tp.currentBlock : null;
    final activeBlocks = tp.activeBlocksForSelectedDate;
    final skippedBlocks = tp.skippedBlocksForSelectedDate;
    final prayers = tp.prayersForSelectedDate;
    final next = isToday ? _nextItem(activeBlocks, prayers) : null;
    final cats = tp.categoryById;
    final holiday = tp.todayHoliday;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        children: [
          _DateHeader(
            selected: tp.selectedDate,
            isToday: isToday,
            onPrev: () => tp.setSelectedDate(
                tp.selectedDate.subtract(const Duration(days: 1))),
            onNext: isToday
                ? null
                : () => tp.setSelectedDate(
                    tp.selectedDate.add(const Duration(days: 1))),
            onTapToday: () => tp.setSelectedDate(DateTime.now()),
          ),
          if (holiday != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Glass(
                borderRadius: BorderRadius.circular(18),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Holiday — ${holiday.name}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Schedule is optional today. Rest up.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: _ProgressHero(
              completed: tp.completedCount,
              total: tp.totalCount,
              progress: tp.progress,
              currentBlock: current,
              currentCategory:
                  current != null ? cats[current.categoryId] : null,
              nextLabel: next?.$1,
              nextTime: next?.$2,
              nextColor: next?.$3,
            ),
          ),
          if (prayers.isNotEmpty) ...[
            const _SectionHeader('Prayers', Icons.mosque_rounded),
            for (final p in prayers)
              _PrayerCard(
                prayer: p,
                onToggle: () => tp.togglePrayer(p),
              ),
            const SizedBox(height: 8),
          ],
          if (activeBlocks.isNotEmpty) ...[
            const _SectionHeader('Schedule', Icons.view_agenda_rounded),
            for (final b in activeBlocks)
              BlockCard(
                block: b,
                category: cats[b.categoryId],
                completed: b.id != null && tp.isCompleted(b.id!),
                isCurrent: current?.id == b.id,
                timeOverridden:
                    b.id != null && tp.hasTimeOverride(b.id!),
                onToggle: () => tp.toggle(b),
                onLongPress: () => _showBlockMenu(context, tp, b),
              ),
          ],
          if (skippedBlocks.isNotEmpty) ...[
            const _SectionHeader('Skipped today', Icons.skip_next_rounded),
            for (final b in skippedBlocks)
              _SkippedCard(
                block: b,
                category: cats[b.categoryId],
                onRestore: () => tp.unskipBlock(b),
              ),
          ],
          // Qada — missed prayers
          if (tp.pendingQada.isNotEmpty && isToday) ...[
            _QadaBanner(
              qadaList: tp.pendingQada,
              onMarkDone: (q) => tp.markQadaDone(q),
              onTapExpand: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QadaScreen()),
              ),
            ),
          ] else if (isToday && AppSettings.I.prayerEnabled) ...[
            // Small link to prayer calendar even when no qada
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QadaScreen()),
                ),
                child: Glass(
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Prayer Calendar & Qada',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                          )),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ],
          // Todos
          if (isToday) ...[
            _TodoSection(
              todos: tp.activeTodos,
              onToggle: (t) => tp.toggleTodo(t),
              onDelete: (t) => tp.deleteTodo(t.id!),
              onAdd: () => _addTodo(context, tp),
            ),
          ],
          if (activeBlocks.isEmpty &&
              prayers.isEmpty &&
              skippedBlocks.isEmpty &&
              tp.activeTodos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Nothing here yet.\nAdd blocks via Edit, or tap + below for todos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

  (String, DateTime, Color)? _nextItem(
      List<Block> blocks, List<PrayerInstance> prayers) {
    final now = DateTime.now();
    (String, DateTime, Color)? best;
    for (final p in prayers) {
      if (p.time.isAfter(now)) {
        if (best == null || p.time.isBefore(best.$2)) {
          best = (p.name.label, p.time, const Color(0xFF00695C));
        }
      }
    }
    for (final b in blocks) {
      final dt = DateTime(
          now.year, now.month, now.day, b.startMinutes ~/ 60, b.startMinutes % 60);
      if (dt.isAfter(now)) {
        if (best == null || dt.isBefore(best.$2)) {
          best = (b.title, dt, const Color(0xFF2E7D32));
        }
      }
    }
    return best;
  }

  void _addTodo(BuildContext context, TrackerProvider tp) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Glass(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    tp.addTodo(v.trim());
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (ctrl.text.trim().isNotEmpty) {
                      tp.addTodo(ctrl.text.trim());
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockMenu(BuildContext context, TrackerProvider tp, Block b) {
    final hasOverride = b.id != null && tp.hasTimeOverride(b.id!);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Glass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(b.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(b.rangeLabel,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Change time today'),
              subtitle: Text(hasOverride
                  ? 'Currently overridden'
                  : 'Only for today, default stays'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onTap: () {
                Navigator.pop(context);
                _changeTimeToday(context, tp, b);
              },
            ),
            if (hasOverride)
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: const Text('Reset to default time'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  tp.clearBlockTimeOverride(b);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.skip_next_rounded),
              title: const Text('Skip for today'),
              subtitle: const Text("Won't count toward progress"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onTap: () {
                tp.skipBlock(b);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_alt_rounded),
              title: const Text('Add note'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onTap: () {
                Navigator.pop(context);
                _editNote(context, tp, b);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeTimeToday(
      BuildContext context, TrackerProvider tp, Block b) async {
    TimeOfDay start = TimeOfDay(
        hour: b.startMinutes ~/ 60, minute: b.startMinutes % 60);
    TimeOfDay end = TimeOfDay(
        hour: b.endMinutes ~/ 60, minute: b.endMinutes % 60);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Glass(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change time — today only',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
              const SizedBox(height: 4),
              Text(
                'Default: ${b.startLabel} – ${b.endLabel}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _TimeBtn(
                      label: 'START',
                      time: start,
                      onTap: () async {
                        final t = await showTimePicker(
                            context: ctx, initialTime: start);
                        if (t != null) setState(() => start = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeBtn(
                      label: 'END',
                      time: end,
                      onTap: () async {
                        final t = await showTimePicker(
                            context: ctx, initialTime: end);
                        if (t != null) setState(() => end = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final sM = start.hour * 60 + start.minute;
                    final eM = end.hour * 60 + end.minute;
                    if (eM <= sM) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('End must be after start')),
                      );
                      return;
                    }
                    tp.setBlockTimeOverride(b, sM, eM);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save for today'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editNote(BuildContext context, TrackerProvider tp, Block b) {
    final ctrl = TextEditingController(
      text: tp.todayCompletions[b.id]?.note ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Glass(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Note — ${b.title}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'How did this block go?',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    tp.setNote(b, ctrl.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader(this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final PrayerInstance prayer;
  final VoidCallback onToggle;
  const _PrayerCard({required this.prayer, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const prayerColor = Color(0xFF00695C);
    final isActive = prayer.isActiveNow;
    final isQada = prayer.isQadaNow;
    final borderColor = isQada
        ? Colors.red.withOpacity(0.6)
        : isActive
            ? prayerColor.withOpacity(0.6)
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.6);
    final tintColor = isQada ? Colors.red.withOpacity(0.06) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GestureDetector(
        onTap: onToggle,
        child: Glass(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          tint: tintColor,
          border: Border.all(
            color: borderColor,
            width: (isActive || isQada) ? 1.5 : 1,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    (isQada ? Colors.red : prayerColor).withOpacity(0.35),
                    (isQada ? Colors.red : prayerColor).withOpacity(0.15),
                  ]),
                  border: Border.all(
                      color: (isQada ? Colors.red : prayerColor)
                          .withOpacity(0.5)),
                ),
                child: Icon(prayer.name.icon,
                    color: isQada ? Colors.red : prayerColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          prayer.name.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: prayer.completed
                                ? cs.onSurfaceVariant
                                : isQada
                                    ? Colors.red
                                    : cs.onSurface,
                            decoration: prayer.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (isQada) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'QADA',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                        if (isActive && !prayer.completed) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${prayer.minutesUntilQada} min left',
                            style: TextStyle(
                              fontSize: 11,
                              color: prayer.minutesUntilQada <= 15
                                  ? Colors.orange
                                  : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('HH:mm').format(prayer.time)} – ${prayer.deadlineLabel}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: prayer.completed
                        ? prayerColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: prayer.completed
                          ? prayerColor
                          : cs.outline.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: prayer.completed
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime selected;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTapToday;
  const _DateHeader({
    required this.selected,
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
          _GlassIconButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTapToday,
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
                      DateFormat('EEEE, d MMM').format(selected),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w700, letterSpacing: -0.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _GlassIconButton(
              icon: Icons.chevron_right_rounded, onTap: onNext ?? () {}),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Glass(
        borderRadius: BorderRadius.circular(999),
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;
  final Block? currentBlock;
  final AppCategory? currentCategory;
  final String? nextLabel;
  final DateTime? nextTime;
  final Color? nextColor;
  const _ProgressHero({
    required this.completed,
    required this.total,
    required this.progress,
    required this.currentBlock,
    required this.currentCategory,
    required this.nextLabel,
    required this.nextTime,
    required this.nextColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final highlight =
        currentCategory?.color ?? nextColor ?? cs.primary;

    final title = currentBlock?.title ?? nextLabel ?? 'Wrap up the day';
    final status =
        currentBlock != null ? 'NOW' : (nextLabel != null ? 'UP NEXT' : 'ALL DONE');
    String sub;
    if (currentBlock != null) {
      sub =
          '${currentBlock!.rangeLabel}  •  ends in ${_untilMin(currentBlock!.endMinutes)}';
    } else if (nextTime != null) {
      final diff = nextTime!.difference(DateTime.now());
      sub =
          '${DateFormat('HH:mm').format(nextTime!)}  •  in ${_untilDuration(diff)}';
    } else {
      sub = 'Great work today';
    }

    return Glass(
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: _Ring(
              progress: progress,
              color: highlight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  Text('$completed / $total',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: highlight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 4),
                Text(sub, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _untilMin(int targetMinutes) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final diff = targetMinutes - nowMin;
    if (diff <= 0) return 'now';
    if (diff < 60) return '$diff min';
    return '${diff ~/ 60}h ${diff % 60}m';
  }

  String _untilDuration(Duration d) {
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
}

class _QadaBanner extends StatelessWidget {
  final List<Qada> qadaList;
  final void Function(Qada) onMarkDone;
  final VoidCallback? onTapExpand;
  const _QadaBanner(
      {required this.qadaList, required this.onMarkDone, this.onTapExpand});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Qada>>{};
    for (final q in qadaList) {
      grouped.putIfAbsent(q.missedDate, () => []).add(q);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Glass(
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.all(16),
        tint: Colors.red.withOpacity(0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded,
                    color: Colors.red.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Qada — Missed prayers (${qadaList.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'These prayers were not marked. Make them up as Qada.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            for (final entry in grouped.entries) ...[
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: entry.value.map((q) {
                  return ActionChip(
                    label: Text(q.prayerLabel),
                    avatar: const Icon(Icons.mosque_rounded, size: 16),
                    onPressed: () => onMarkDone(q),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tap a prayer to mark its Qada as made up.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
                if (onTapExpand != null)
                  TextButton.icon(
                    onPressed: onTapExpand,
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text('Calendar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
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

class _TodoSection extends StatelessWidget {
  final List<Todo> todos;
  final void Function(Todo) onToggle;
  final void Function(Todo) onDelete;
  final VoidCallback onAdd;
  const _TodoSection({
    required this.todos,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.task_alt_rounded,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'TODOS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAdd,
                child: Glass(
                  borderRadius: BorderRadius.circular(999),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: cs.primary),
                      const SizedBox(width: 4),
                      Text('Add',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: cs.primary,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (todos.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Text('No pending todos.',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        for (final t in todos)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 3, 16, 3),
            child: Dismissible(
              key: ValueKey('todo_${t.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.red),
              ),
              onDismissed: (_) => onDelete(t),
              child: GestureDetector(
                onTap: () => onToggle(t),
                child: Glass(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => onToggle(t),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: cs.outline.withOpacity(0.6), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SkippedCard extends StatelessWidget {
  final Block block;
  final AppCategory? category;
  final VoidCallback onRestore;
  const _SkippedCard({
    required this.block,
    required this.category,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Glass(
        borderRadius: BorderRadius.circular(18),
        opacity: 0.4,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Icon(Icons.skip_next_rounded,
                color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                block.title,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(block.rangeLabel,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRestore,
              child: const Text('Restore'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBtn extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeBtn(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double progress;
  final Color color;
  final Widget child;
  const _Ring(
      {required this.progress, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(
        progress: progress,
        color: color,
        track: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(child: child),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  _RingPainter(
      {required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final bg = Paint()
      ..color = track.withOpacity(0.6)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.4), color],
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
      ).createShader(rect)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, bg);
    if (progress > 0) {
      canvas.drawArc(
          rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

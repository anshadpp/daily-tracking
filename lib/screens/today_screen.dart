import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/block.dart';
import '../models/category.dart';
import '../models/prayer.dart';
import '../providers/tracker_provider.dart';
import '../widgets/block_card.dart';
import '../widgets/glass.dart';

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
    final blocks = tp.blocksForSelectedDate;
    final prayers = tp.prayersForSelectedDate;
    final next = isToday ? _nextItem(blocks, prayers) : null;
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
          if (blocks.isNotEmpty) ...[
            const _SectionHeader('Schedule', Icons.view_agenda_rounded),
            for (final b in blocks)
              BlockCard(
                block: b,
                category: cats[b.categoryId],
                completed: b.id != null && tp.isCompleted(b.id!),
                isCurrent: current?.id == b.id,
                onToggle: () => tp.toggle(b),
                onLongPress: () => _editNote(context, tp, b),
              ),
          ],
          if (blocks.isEmpty && prayers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Nothing scheduled. Open Edit to add blocks.',
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
    final now = DateTime.now();
    final isNow = now.isAfter(prayer.time) &&
        now.isBefore(prayer.time.add(const Duration(minutes: 45)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GestureDetector(
        onTap: onToggle,
        child: Glass(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          border: Border.all(
            color: isNow
                ? prayerColor.withOpacity(0.6)
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.6),
            width: isNow ? 1.5 : 1,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    prayerColor.withOpacity(0.35),
                    prayerColor.withOpacity(0.15),
                  ]),
                  border: Border.all(color: prayerColor.withOpacity(0.5)),
                ),
                child: Icon(prayer.name.icon, color: prayerColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.name.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: prayer.completed
                            ? cs.onSurfaceVariant
                            : cs.onSurface,
                        decoration: prayer.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('HH:mm').format(prayer.time),
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
                    color:
                        prayer.completed ? prayerColor : Colors.transparent,
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

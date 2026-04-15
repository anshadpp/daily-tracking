import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/block.dart';
import '../models/category.dart';
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
    final next = isToday ? _nextBlock(tp) : null;
    final cats = tp.categoryById;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _ProgressHero(
              completed: tp.completedCount,
              total: tp.blocks.length,
              progress: tp.progress,
              current: current,
              currentCategory:
                  current != null ? cats[current.categoryId] : null,
              next: next,
              nextCategory: next != null ? cats[next.categoryId] : null,
            ),
          ),
          if (tp.blocks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No blocks yet. Tap the tune icon to add some.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          for (final b in tp.blocks)
            BlockCard(
              block: b,
              category: cats[b.categoryId],
              completed: b.id != null && tp.isCompleted(b.id!),
              isCurrent: current?.id == b.id,
              onToggle: () => tp.toggle(b),
              onLongPress: () => _editNote(context, tp, b),
            ),
        ],
      ),
    );
  }

  Block? _nextBlock(TrackerProvider tp) {
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    for (final b in tp.blocks) {
      if (b.startMinutes > mins) return b;
    }
    return null;
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
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
  final Block? current;
  final AppCategory? currentCategory;
  final Block? next;
  final AppCategory? nextCategory;
  const _ProgressHero({
    required this.completed,
    required this.total,
    required this.progress,
    required this.current,
    required this.currentCategory,
    required this.next,
    required this.nextCategory,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final highlight = currentCategory?.color ??
        nextCategory?.color ??
        cs.primary;

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
                  current != null
                      ? 'NOW'
                      : (next != null ? 'UP NEXT' : 'ALL DONE'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: highlight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  current?.title ?? next?.title ?? 'Wrap up the day',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  current != null
                      ? '${current!.rangeLabel}  •  ends in ${_until(current!.endMinutes)}'
                      : next != null
                          ? '${next!.rangeLabel}  •  in ${_until(next!.startMinutes)}'
                          : 'Great work today',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _until(int targetMinutes) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final diff = targetMinutes - nowMin;
    if (diff <= 0) return 'now';
    if (diff < 60) return '$diff min';
    final h = diff ~/ 60;
    final m = diff % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/block.dart';
import '../providers/tracker_provider.dart';
import '../widgets/block_card.dart';

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
    final cs = Theme.of(context).colorScheme;
    final isToday = _sameDay(tp.selectedDate, DateTime.now());
    final current = isToday ? tp.currentBlock : null;
    final next = isToday ? _nextBlock(tp) : null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _ProgressHero(
              completed: tp.completedCount,
              total: tp.blocks.length,
              progress: tp.progress,
              current: current,
              next: next,
            ),
          ),
          if (tp.blocks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No blocks yet. Tap the tune icon to add some.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          for (final b in tp.blocks)
            BlockCard(
              block: b,
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
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
                  borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              onTap: onTapToday,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      isToday ? 'TODAY' : 'JUMP TO TODAY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEE, d MMM').format(selected),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;
  final Block? current;
  final Block? next;
  const _ProgressHero({
    required this.completed,
    required this.total,
    required this.progress,
    required this.current,
    required this.next,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final highlight = current?.priority.color ?? cs.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlight.withOpacity(0.18),
            cs.surfaceContainerHighest.withOpacity(0.6),
          ],
        ),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: _Ring(
              progress: progress,
              color: highlight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text('$completed/$total',
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
                  current != null ? 'NOW' : (next != null ? 'UP NEXT' : 'ALL DONE'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: highlight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  current?.title ?? next?.title ?? 'Wrap up the day',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  current != null
                      ? '${current!.rangeLabel} • ends in ${_timeUntil(current!.endMinutes)}'
                      : next != null
                          ? '${next!.rangeLabel} • in ${_timeUntil(next!.startMinutes)}'
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

  String _timeUntil(int targetMinutes) {
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
  const _Ring({required this.progress, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(
        progress: progress,
        color: color,
        track: Theme.of(context).colorScheme.surfaceContainerHigh,
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
    final stroke = 8.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final bg = Paint()
      ..color = track
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.6), color],
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

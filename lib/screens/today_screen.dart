import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/block.dart';
import '../providers/tracker_provider.dart';
import '../widgets/block_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    final isToday = _sameDay(tp.selectedDate, DateTime.now());
    final dateLabel = isToday
        ? 'Today • ${DateFormat('EEE, d MMM').format(tp.selectedDate)}'
        : DateFormat('EEE, d MMM yyyy').format(tp.selectedDate);
    final current = isToday ? tp.currentBlock : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => tp.setSelectedDate(
                    tp.selectedDate.subtract(const Duration(days: 1))),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    children: [
                      Text(dateLabel,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${tp.completedCount} / ${tp.blocks.length} done • ${(tp.progress * 100).round()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: isToday
                    ? null
                    : () => tp.setSelectedDate(
                        tp.selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: tp.progress,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: tp.blocks.isEmpty
              ? const Center(child: Text('No blocks yet. Add some in Edit.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: tp.blocks.length,
                  itemBuilder: (ctx, i) {
                    final b = tp.blocks[i];
                    return BlockCard(
                      block: b,
                      completed: b.id != null && tp.isCompleted(b.id!),
                      isCurrent: current?.id == b.id,
                      onToggle: () => tp.toggle(b),
                      onLongPress: () => _editNote(context, tp, b),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _editNote(BuildContext context, TrackerProvider tp, Block b) {
    final ctrl = TextEditingController(
      text: tp.todayCompletions[b.id]?.note ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Note — ${b.title}'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'How did this block go?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              tp.setNote(b, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

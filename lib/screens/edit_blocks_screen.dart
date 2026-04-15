import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/block.dart';
import '../providers/tracker_provider.dart';

class EditBlocksScreen extends StatelessWidget {
  const EditBlocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: tp.blocks.length,
        itemBuilder: (_, i) {
          final b = tp.blocks[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: b.priority.color.withOpacity(0.15),
              child: Icon(Icons.schedule, color: b.priority.color, size: 18),
            ),
            title: Text(b.title),
            subtitle: Text('${b.rangeLabel} • ${b.priority.label}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: b.notify,
                  onChanged: (v) =>
                      tp.upsertBlock(b.copyWith(notify: v)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, tp, b),
                ),
              ],
            ),
            onTap: () => _editBlockDialog(context, tp, b),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New block'),
        onPressed: () => _editBlockDialog(context, tp, null),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TrackerProvider tp, Block b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${b.title}"?'),
        content: const Text('This also removes its history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              tp.deleteBlock(b.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editBlockDialog(
      BuildContext context, TrackerProvider tp, Block? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    TimeOfDay start = existing == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(
            hour: existing.startMinutes ~/ 60,
            minute: existing.startMinutes % 60);
    TimeOfDay end = existing == null
        ? const TimeOfDay(hour: 10, minute: 0)
        : TimeOfDay(
            hour: existing.endMinutes ~/ 60,
            minute: existing.endMinutes % 60);
    Priority priority = existing?.priority ?? Priority.core;
    bool notify = existing?.notify ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'New block' : 'Edit block'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                              context: ctx, initialTime: start);
                          if (t != null) setState(() => start = t);
                        },
                        child: Text('Start: ${start.format(ctx)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                              context: ctx, initialTime: end);
                          if (t != null) setState(() => end = t);
                        },
                        child: Text('End: ${end.format(ctx)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Priority>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: Priority.values
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(p.label)))
                      .toList(),
                  onChanged: (p) =>
                      setState(() => priority = p ?? priority),
                ),
                SwitchListTile(
                  title: const Text('Daily reminder'),
                  value: notify,
                  onChanged: (v) => setState(() => notify = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final sM = start.hour * 60 + start.minute;
                final eM = end.hour * 60 + end.minute;
                if (eM <= sM) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('End must be after start')),
                  );
                  return;
                }
                final block = (existing ??
                        Block(
                          title: '',
                          description: '',
                          startMinutes: 0,
                          endMinutes: 0,
                          orderIndex: tp.blocks.length,
                          priority: Priority.core,
                        ))
                    .copyWith(
                  title: title,
                  description: descCtrl.text.trim(),
                  startMinutes: sM,
                  endMinutes: eM,
                  priority: priority,
                  notify: notify,
                );
                tp.upsertBlock(block);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

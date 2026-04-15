import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/tracker_provider.dart';
import '../widgets/glass.dart';

class HolidaysScreen extends StatelessWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Holidays / Off days')),
      body: GlassBackground(
        child: tp.holidays.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No holidays yet.\nAdd a date to pause the schedule.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                itemCount: tp.holidays.length,
                itemBuilder: (_, i) {
                  final h = tp.holidays[i];
                  final d = DateTime.parse(h.date);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Glass(
                      borderRadius: BorderRadius.circular(18),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.event_busy_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEE, d MMM yyyy').format(d),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                                Icons.delete_outline_rounded),
                            onPressed: () => tp.deleteHoliday(h.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addHoliday(context, tp),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add holiday'),
      ),
    );
  }

  void _addHoliday(BuildContext context, TrackerProvider tp) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final nameCtrl = TextEditingController(text: 'Holiday');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(DateFormat('EEE, d MMM yyyy').format(date)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration:
              const InputDecoration(labelText: 'Label (e.g. Eid, Sick day)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await tp.addHoliday(date, nameCtrl.text.trim());
    }
  }
}

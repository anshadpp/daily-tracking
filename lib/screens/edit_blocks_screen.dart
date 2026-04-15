import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/block.dart';
import '../models/category.dart';
import '../providers/tracker_provider.dart';
import '../widgets/glass.dart';
import 'categories_screen.dart';

class EditBlocksScreen extends StatelessWidget {
  const EditBlocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    final cats = tp.categoryById;
    return Scaffold(
      body: GlassBackground(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
          itemCount: tp.blocks.length,
          itemBuilder: (_, i) {
            final b = tp.blocks[i];
            final c = cats[b.categoryId];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Glass(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (c?.color ?? Colors.grey).withOpacity(0.18),
                        border: Border.all(
                            color: (c?.color ?? Colors.grey)
                                .withOpacity(0.4)),
                      ),
                      child: Icon(
                        c?.icon ?? Icons.schedule_rounded,
                        color: c?.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            '${b.rangeLabel}  •  ${c?.name ?? '—'}  •  ${b.isEvent ? '📅 ${b.specificDate}' : DaysOfWeek.label(b.daysOfWeek)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: b.notify,
                      onChanged: (v) =>
                          tp.upsertBlock(b.copyWith(notify: v)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _editBlockDialog(context, tp, b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _confirmDelete(context, tp, b),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'cats',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CategoriesScreen()),
            ),
            child: const Icon(Icons.palette_rounded),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'new',
            onPressed: () => _editBlockDialog(context, tp, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New block'),
          ),
        ],
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
    final descCtrl = TextEditingController(text: existing?.description ?? '');
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
    final routineCats = tp.routineCategories;
    int categoryId = existing?.categoryId ??
        (routineCats.isNotEmpty ? routineCats.first.id! : 1);
    bool notify = existing?.notify ?? true;
    int daysOfWeek = existing?.daysOfWeek ?? DaysOfWeek.all;
    bool isEvent = existing?.specificDate != null;
    DateTime? specificDate = existing?.specificDate != null
        ? DateTime.parse(existing!.specificDate!)
        : null;

    showModalBottomSheet(
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
                    existing == null ? 'New block' : 'Edit block',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: titleCtrl, decoration: _deco('Title')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    decoration: _deco('Description (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePill(
                          label: 'Start',
                          time: start,
                          onPick: () async {
                            final t = await showTimePicker(
                                context: ctx, initialTime: start);
                            if (t != null) setState(() => start = t);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimePill(
                          label: 'End',
                          time: end,
                          onPick: () async {
                            final t = await showTimePicker(
                                context: ctx, initialTime: end);
                            if (t != null) setState(() => end = t);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('CATEGORY'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in routineCats)
                        _CategoryChip(
                          category: c,
                          selected: c.id == categoryId,
                          onTap: () => setState(() => categoryId = c.id!),
                        ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CategoriesScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Theme.of(ctx)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 16),
                              SizedBox(width: 4),
                              Text('New',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    title: const Text('One-off event'),
                    subtitle: const Text(
                        'Only appears on a specific date, not recurring'),
                    value: isEvent,
                    onChanged: (v) => setState(() {
                      isEvent = v;
                      if (v) {
                        specificDate ??= DateTime.now();
                      } else {
                        specificDate = null;
                      }
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (isEvent) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: specificDate ?? DateTime.now(),
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 30)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) {
                          setState(() => specificDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(ctx)
                                .colorScheme
                                .outline
                                .withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded),
                            const SizedBox(width: 10),
                            Text(
                              specificDate == null
                                  ? 'Pick date'
                                  : '${specificDate!.year}-${specificDate!.month.toString().padLeft(2, '0')}-${specificDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    const _SectionLabel('REPEATS ON'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 1; i <= 7; i++)
                          _DayToggle(
                            label: DaysOfWeek.names[i - 1],
                            selected: DaysOfWeek.has(daysOfWeek, i),
                            onTap: () => setState(() {
                              daysOfWeek ^= DaysOfWeek.bit(i);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _Preset(
                            label: 'Every day',
                            onTap: () => setState(
                                () => daysOfWeek = DaysOfWeek.all)),
                        _Preset(
                            label: 'Weekdays',
                            onTap: () => setState(
                                () => daysOfWeek = DaysOfWeek.weekdays)),
                        _Preset(
                            label: 'Weekends',
                            onTap: () => setState(
                                () => daysOfWeek = DaysOfWeek.weekends)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Daily reminder'),
                    value: notify,
                    onChanged: (v) => setState(() => notify = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
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
                                  categoryId: categoryId,
                                ))
                            .copyWith(
                          title: title,
                          description: descCtrl.text.trim(),
                          startMinutes: sM,
                          endMinutes: eM,
                          categoryId: categoryId,
                          notify: notify,
                          daysOfWeek: isEvent ? DaysOfWeek.all : daysOfWeek,
                          specificDate: isEvent && specificDate != null
                              ? '${specificDate!.year}-${specificDate!.month.toString().padLeft(2, '0')}-${specificDate!.day.toString().padLeft(2, '0')}'
                              : null,
                        );
                        tp.upsertBlock(block);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );
}

class _TimePill extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onPick;
  const _TimePill(
      {required this.label, required this.time, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final AppCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

class _DayToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DayToggle(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? cs.primary : Colors.transparent,
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withOpacity(0.5),
            width: selected ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Preset({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(label),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/tracker_provider.dart';
import '../widgets/glass.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: GlassBackground(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: tp.categories.length,
          itemBuilder: (_, i) {
            final c = tp.categories[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Glass(
                borderRadius: BorderRadius.circular(22),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            c.color.withOpacity(0.35),
                            c.color.withOpacity(0.15),
                          ],
                        ),
                        border: Border.all(color: c.color.withOpacity(0.5)),
                      ),
                      child: Icon(c.icon, color: c.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            c.isBuiltIn ? 'Built-in' : 'Custom',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _edit(context, tp, c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: tp.categories.length <= 1
                          ? null
                          : () => _confirmDelete(context, tp, c),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, tp, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New category'),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, TrackerProvider tp, AppCategory c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${c.name}"?'),
        content: const Text(
            'Blocks using this category will be reassigned to another category.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              tp.deleteCategory(c.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _edit(
      BuildContext context, TrackerProvider tp, AppCategory? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    int colorValue = existing?.colorValue ?? CategoryPalette.colors.first;
    int iconCode = existing?.iconCodePoint ??
        CategoryPalette.icons.first.codePoint;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'New category' : 'Edit category',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _Label('COLOR'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryPalette.colors.map((cv) {
                    final selected = cv == colorValue;
                    return GestureDetector(
                      onTap: () => setState(() => colorValue = cv),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(cv),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Color(cv).withOpacity(0.6),
                                    blurRadius: 10,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const _Label('ICON'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryPalette.icons.map((ic) {
                    final selected = ic.codePoint == iconCode;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => iconCode = ic.codePoint),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selected
                              ? Color(colorValue).withOpacity(0.2)
                              : Theme.of(ctx)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Color(colorValue)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(ic,
                            color: selected
                                ? Color(colorValue)
                                : Theme.of(ctx)
                                    .colorScheme
                                    .onSurfaceVariant),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final cat = (existing ??
                              AppCategory(
                                name: '',
                                colorValue: colorValue,
                                iconCodePoint: iconCode,
                              ))
                          .copyWith(
                        name: name,
                        colorValue: colorValue,
                        iconCodePoint: iconCode,
                      );
                      tp.upsertCategory(cat);
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
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
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

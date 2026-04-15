import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/tracker_provider.dart';
import '../widgets/glass.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  CategoryKind get _currentKind =>
      _tab.index == 0 ? CategoryKind.routine : CategoryKind.expense;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tab,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(
              icon: Icon(Icons.schedule_rounded),
              text: 'Routine',
            ),
            Tab(
              icon: Icon(Icons.account_balance_wallet_rounded),
              text: 'Expenses',
            ),
          ],
        ),
      ),
      body: GlassBackground(
        child: TabBarView(
          controller: _tab,
          children: [
            _CategoryList(
              categories: tp.routineCategories,
              onEdit: (c) => _edit(context, tp, c, CategoryKind.routine),
              onDelete: (c) => _confirmDelete(context, tp, c),
              emptyText: 'No routine categories',
            ),
            _CategoryList(
              categories: tp.expenseCategories,
              onEdit: (c) => _edit(context, tp, c, CategoryKind.expense),
              onDelete: (c) => _confirmDelete(context, tp, c),
              emptyText: 'No expense categories',
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: FloatingActionButton.extended(
          onPressed: () => _edit(context, tp, null, _currentKind),
          icon: const Icon(Icons.add_rounded),
          label: Text(_currentKind == CategoryKind.routine
              ? 'New routine category'
              : 'New expense category'),
        ),
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
            'Items using this category will be reassigned to another category of the same type.'),
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

  void _edit(BuildContext context, TrackerProvider tp, AppCategory? existing,
      CategoryKind kind) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    int colorValue = existing?.colorValue ?? CategoryPalette.colors.first;
    int iconCode = existing?.iconCodePoint ??
        CategoryPalette.icons.first.codePoint;
    final isEdit = existing != null;

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
                    isEdit
                        ? 'Edit category'
                        : (kind == CategoryKind.routine
                            ? 'New routine category'
                            : 'New expense category'),
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
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
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
                                  kind: kind,
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
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<AppCategory> categories;
  final void Function(AppCategory) onEdit;
  final void Function(AppCategory) onDelete;
  final String emptyText;
  const _CategoryList({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final c = categories[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Glass(
            borderRadius: BorderRadius.circular(22),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  onPressed: () => onEdit(c),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: categories.length <= 1
                      ? null
                      : () => onDelete(c),
                ),
              ],
            ),
          ),
        );
      },
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

import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../models/block.dart';
import '../models/category.dart';
import '../models/completion.dart';
import '../services/notification_service.dart';

class TrackerProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<Block> _blocks = [];
  List<AppCategory> _categories = [];
  Map<int, Completion> _todayCompletions = {};
  DateTime _selectedDate = DateTime.now();

  List<Block> get blocks => _blocks;
  List<AppCategory> get categories => _categories;
  Map<int, AppCategory> get categoryById =>
      {for (final c in _categories) c.id!: c};
  Map<int, Completion> get todayCompletions => _todayCompletions;
  DateTime get selectedDate => _selectedDate;

  AppCategory? categoryFor(Block b) => categoryById[b.categoryId];

  String get _selectedDateStr {
    final d = _selectedDate;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool isCompleted(int blockId) =>
      _todayCompletions[blockId]?.completed ?? false;

  int get completedCount =>
      _blocks.where((b) => b.id != null && isCompleted(b.id!)).length;

  double get progress => _blocks.isEmpty ? 0 : completedCount / _blocks.length;

  Future<void> load() async {
    _categories = await _db.getCategories();
    _blocks = await _db.getBlocks(activeOnly: true);
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    notifyListeners();
  }

  Future<void> setSelectedDate(DateTime d) async {
    _selectedDate = DateTime(d.year, d.month, d.day);
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    notifyListeners();
  }

  Future<void> toggle(Block b) async {
    if (b.id == null) return;
    final current = isCompleted(b.id!);
    final now = DateTime.now();
    await _db.setCompletion(
      blockId: b.id!,
      date: _selectedDateStr,
      completed: !current,
      completedAtMinutes: !current ? now.hour * 60 + now.minute : null,
    );
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    notifyListeners();
  }

  Future<void> setNote(Block b, String note) async {
    if (b.id == null) return;
    await _db.setCompletion(
      blockId: b.id!,
      date: _selectedDateStr,
      completed: isCompleted(b.id!),
      completedAtMinutes: _todayCompletions[b.id!]?.completedAtMinutes,
      note: note,
    );
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    notifyListeners();
  }

  Future<void> upsertBlock(Block b) async {
    if (b.id == null) {
      await _db.insertBlock(b);
    } else {
      await _db.updateBlock(b);
    }
    await load();
    await NotificationService.instance.rescheduleAll(_blocks, categoryById);
  }

  Future<void> deleteBlock(int id) async {
    await _db.deleteBlock(id);
    await load();
    await NotificationService.instance.rescheduleAll(_blocks, categoryById);
  }

  Future<void> upsertCategory(AppCategory c) async {
    if (c.id == null) {
      await _db.insertCategory(c);
    } else {
      await _db.updateCategory(c);
    }
    await load();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await load();
  }

  Future<void> rescheduleNotifications() async {
    await NotificationService.instance.rescheduleAll(_blocks, categoryById);
  }

  Block? get currentBlock {
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    for (final b in _blocks) {
      if (mins >= b.startMinutes && mins < b.endMinutes) return b;
    }
    return null;
  }
}

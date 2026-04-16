import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../models/block.dart';
import '../models/category.dart';
import '../models/completion.dart';
import '../models/holiday.dart';
import '../models/prayer.dart';
import '../models/qada.dart';
import '../models/todo.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/settings_service.dart';
import '../services/widget_service.dart';

class TrackerProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<Block> _blocks = [];
  List<AppCategory> _categories = [];
  Map<int, Completion> _todayCompletions = {};
  Map<String, PrayerCompletion> _prayerCompletions = {};
  List<Holiday> _holidays = [];
  Holiday? _todayHoliday;
  List<Todo> _activeTodos = [];
  List<Qada> _pendingQada = [];
  DateTime _selectedDate = DateTime.now();

  List<Block> get blocks => _blocks;
  List<AppCategory> get categories => _categories;
  List<AppCategory> get routineCategories =>
      _categories.where((c) => c.kind == CategoryKind.routine).toList();
  List<AppCategory> get expenseCategories =>
      _categories.where((c) => c.kind == CategoryKind.expense).toList();
  List<Holiday> get holidays => _holidays;
  Holiday? get todayHoliday => _todayHoliday;
  List<Todo> get activeTodos => _activeTodos;
  List<Qada> get pendingQada => _pendingQada;
  Map<int, AppCategory> get categoryById =>
      {for (final c in _categories) c.id!: c};
  Map<int, Completion> get todayCompletions => _todayCompletions;
  Map<String, PrayerCompletion> get prayerCompletions => _prayerCompletions;
  DateTime get selectedDate => _selectedDate;

  AppCategory? categoryFor(Block b) => categoryById[b.categoryId];

  List<Block> get blocksForSelectedDate {
    final raw = _blocks.where((b) => b.occursOn(_selectedDate)).toList();
    // Apply per-day time overrides from completions
    final withOverrides = raw.map((b) {
      if (b.id == null) return b;
      final c = _todayCompletions[b.id!];
      if (c != null && c.hasTimeOverride) {
        return b.copyWith(
          startMinutes: c.overrideStart ?? b.startMinutes,
          endMinutes: c.overrideEnd ?? b.endMinutes,
        );
      }
      return b;
    }).toList();
    withOverrides.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return withOverrides;
  }

  List<PrayerInstance> get prayersForSelectedDate {
    if (!AppSettings.I.prayerEnabled) return const [];
    final computed = PrayerService.instance.forDate(_selectedDate);
    return computed
        .map<PrayerInstance>((p) => PrayerInstance(
              name: p.name,
              time: p.time,
              deadline: p.deadline,
              completed:
                  _prayerCompletions[p.name.key]?.completed ?? false,
            ))
        .toList();
  }

  String get _selectedDateStr => _dateStr(_selectedDate);

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isCompleted(int blockId) =>
      _todayCompletions[blockId]?.completed ?? false;

  bool isSkipped(int blockId) =>
      _todayCompletions[blockId]?.skipped ?? false;

  List<Block> get activeBlocksForSelectedDate =>
      blocksForSelectedDate
          .where((b) => b.id == null || !isSkipped(b.id!))
          .toList();

  List<Block> get skippedBlocksForSelectedDate =>
      blocksForSelectedDate
          .where((b) => b.id != null && isSkipped(b.id!))
          .toList();

  int get completedCount {
    final bs = activeBlocksForSelectedDate;
    int n = bs.where((b) => b.id != null && isCompleted(b.id!)).length;
    for (final p in prayersForSelectedDate) {
      if (p.completed) n++;
    }
    return n;
  }

  int get totalCount =>
      activeBlocksForSelectedDate.length + prayersForSelectedDate.length;

  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  Future<void> load() async {
    _categories = await _db.getCategories();
    _blocks = await _db.getBlocks(activeOnly: true);
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    _prayerCompletions = await _db.getPrayerCompletions(_selectedDateStr);
    _holidays = await _db.getHolidays();
    _todayHoliday = await _db.getHolidayForDate(_selectedDateStr);
    _activeTodos = await _db.getActiveTodos();

    // Check all days from install to yesterday for missed prayers → Qada
    if (AppSettings.I.prayerEnabled && AppSettings.I.installDate != null) {
      await _db.checkAndInsertQadaRange(
          AppSettings.I.installDate!, DateTime.now());
    }
    _pendingQada = await _db.getPendingQada();

    notifyListeners();
    _pushWidget();
  }

  PrayerInstance? get currentPrayer {
    if (!AppSettings.I.prayerEnabled) return null;
    for (final p in prayersForSelectedDate) {
      if (p.isActiveNow && !p.completed) return p;
    }
    return null;
  }

  void _pushWidget() {
    final cur = currentBlock;
    final cat = cur != null ? categoryById[cur.categoryId] : null;
    final curPrayer = currentPrayer;
    DateTime? nextTime;
    String? nextTitle;
    final active = activeBlocksForSelectedDate;
    final prayers = prayersForSelectedDate;

    if (cur == null && curPrayer == null) {
      final now = DateTime.now();
      // Check next prayer first
      for (final p in prayers) {
        if (p.time.isAfter(now) && !p.completed) {
          nextTitle = '🕌 ${p.name.label}';
          nextTime = p.time;
          break;
        }
      }
      // Check next block, pick whichever is sooner
      final nowMin = now.hour * 60 + now.minute;
      for (final b in active) {
        if (b.startMinutes > nowMin) {
          final bt = DateTime(now.year, now.month, now.day,
              b.startMinutes ~/ 60, b.startMinutes % 60);
          if (nextTime == null || bt.isBefore(nextTime!)) {
            nextTitle = b.title;
            nextTime = bt;
          }
          break;
        }
      }
    }
    final doneIds = <int>{};
    for (final b in active) {
      if (b.id != null && isCompleted(b.id!)) doneIds.add(b.id!);
    }
    final prayersDone = prayers.where((p) => p.completed).length;
    WidgetService.instance.push(
      completed: completedCount,
      total: totalCount,
      todayBlocks: active,
      completedIds: doneIds,
      todos: _activeTodos,
      currentBlock: cur,
      currentCategory: cat,
      currentPrayerLabel: curPrayer != null
          ? '🕌 ${curPrayer.name.label}'
          : null,
      currentPrayerDeadline: curPrayer?.deadlineLabel,
      nextTitle: nextTitle,
      nextTime: nextTime,
      prayers: prayers,
      prayersDone: prayersDone,
    );
  }

  Future<void> toggleCurrentFromWidget() async {
    final b = currentBlock;
    if (b != null) {
      await toggle(b);
    }
  }

  Future<void> setSelectedDate(DateTime d) async {
    _selectedDate = DateTime(d.year, d.month, d.day);
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    _prayerCompletions = await _db.getPrayerCompletions(_selectedDateStr);
    _todayHoliday = await _db.getHolidayForDate(_selectedDateStr);
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

  bool get isViewingPastDate {
    final now = DateTime.now();
    return _selectedDate.year < now.year ||
        (_selectedDate.year == now.year &&
            (_selectedDate.month < now.month ||
                (_selectedDate.month == now.month &&
                    _selectedDate.day < now.day)));
  }

  Future<void> togglePrayer(PrayerInstance p) async {
    final now = DateTime.now();
    await _db.setPrayerCompletion(
      date: _selectedDateStr,
      prayer: p.name.key,
      completed: !p.completed,
      completedAtMinutes: !p.completed ? now.hour * 60 + now.minute : null,
    );
    _prayerCompletions = await _db.getPrayerCompletions(_selectedDateStr);
    notifyListeners();
    _pushWidget();
  }

  /// Mark a past prayer as Qada made-up (inserts into qada table too)
  Future<void> markPastPrayerAsQada(PrayerInstance p) async {
    await _db.addManualQada(_selectedDateStr, [p.name.key]);
    // Then mark it as made up
    final pending = await _db.getPendingQada();
    final match = pending.where(
        (q) => q.prayer == p.name.key && q.missedDate == _selectedDateStr);
    if (match.isNotEmpty) {
      await _db.markQadaDone(match.first.id!);
    }
    _prayerCompletions = await _db.getPrayerCompletions(_selectedDateStr);
    _pendingQada = await _db.getPendingQada();
    notifyListeners();
    _pushWidget();
  }

  Future<void> setBlockTimeOverride(
      Block b, int startMin, int endMin) async {
    if (b.id == null) return;
    await _db.setTimeOverride(
      blockId: b.id!,
      date: _selectedDateStr,
      startMinutes: startMin,
      endMinutes: endMin,
    );
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    notifyListeners();
    _pushWidget();
  }

  Future<void> clearBlockTimeOverride(Block b) async {
    if (b.id == null) return;
    await _db.setTimeOverride(
      blockId: b.id!,
      date: _selectedDateStr,
      startMinutes: null,
      endMinutes: null,
    );
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    notifyListeners();
    _pushWidget();
  }

  bool hasTimeOverride(int blockId) =>
      _todayCompletions[blockId]?.hasTimeOverride ?? false;

  Future<void> skipBlock(Block b) async {
    if (b.id == null) return;
    await _db.setSkipped(
        blockId: b.id!, date: _selectedDateStr, skipped: true);
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    notifyListeners();
    _pushWidget();
  }

  Future<void> unskipBlock(Block b) async {
    if (b.id == null) return;
    await _db.setSkipped(
        blockId: b.id!, date: _selectedDateStr, skipped: false);
    _todayCompletions = await _db.getCompletionsForDate(_selectedDateStr);
    notifyListeners();
    _pushWidget();
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

  Future<void> addHoliday(DateTime date, String name) async {
    await _db.insertHoliday(Holiday(date: _dateStr(date), name: name));
    await load();
  }

  Future<void> deleteHoliday(int id) async {
    await _db.deleteHoliday(id);
    await load();
  }

  // Todos
  Future<void> addTodo(String title) async {
    await _db.insertTodo(Todo(
      title: title,
      createdAt: _dateStr(DateTime.now()),
    ));
    _activeTodos = await _db.getActiveTodos();
    notifyListeners();
    _pushWidget();
  }

  Future<void> toggleTodo(Todo t) async {
    await _db.toggleTodo(t.id!, !t.completed);
    _activeTodos = await _db.getActiveTodos();
    notifyListeners();
    _pushWidget();
  }

  Future<void> deleteTodo(int id) async {
    await _db.deleteTodo(id);
    _activeTodos = await _db.getActiveTodos();
    notifyListeners();
    _pushWidget();
  }

  // Qada
  Future<void> markQadaDone(Qada q) async {
    await _db.markQadaDone(q.id!);
    _pendingQada = await _db.getPendingQada();
    _prayerCompletions = await _db.getPrayerCompletions(_selectedDateStr);
    notifyListeners();
    _pushWidget();
  }

  Future<void> undoQadaMadeUp(Qada q) async {
    await _db.undoQadaMadeUp(q.id!);
    _pendingQada = await _db.getPendingQada();
    notifyListeners();
    _pushWidget();
  }

  Future<void> addManualQada(DateTime date, List<String> prayers) async {
    await _db.addManualQada(_dateStr(date), prayers);
    _pendingQada = await _db.getPendingQada();
    notifyListeners();
    _pushWidget();
  }

  Future<void> rescheduleNotifications() async {
    await NotificationService.instance.rescheduleAll(_blocks, categoryById);
  }

  Block? get currentBlock {
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    final today = _sameDay(_selectedDate, now) ? _selectedDate : now;
    for (final b in _blocks) {
      if (!b.occursOn(today)) continue;
      if (mins >= b.startMinutes && mins < b.endMinutes) return b;
    }
    return null;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

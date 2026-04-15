import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/block.dart';
import '../models/category.dart';
import '../models/completion.dart';
import '../models/expense.dart';
import '../models/holiday.dart';
import '../models/prayer.dart';
import 'default_blocks.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'daily_tracker.db'),
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        is_builtin INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE blocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        start_minutes INTEGER NOT NULL,
        end_minutes INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        notify INTEGER NOT NULL DEFAULT 1,
        days_of_week INTEGER NOT NULL DEFAULT 127,
        specific_date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        block_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        completed_at_minutes INTEGER,
        note TEXT,
        UNIQUE(block_id, date)
      )
    ''');
    await db.execute('CREATE INDEX idx_completions_date ON completions(date)');
    await db.execute('''
      CREATE TABLE holidays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE prayer_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        prayer TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        completed_at_minutes INTEGER,
        UNIQUE(date, prayer)
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        minutes_of_day INTEGER,
        amount_cents INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        category_id INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');

    final catIds = <String, int>{};
    for (final c in DefaultCategories.all()) {
      final id = await db.insert('categories', c.toMap()..remove('id'));
      catIds[c.name] = id;
    }

    final batch = db.batch();
    for (final seed in defaultBlockSeeds) {
      final catId = catIds[seed.categoryName] ?? catIds.values.first;
      batch.insert('blocks', seed.toBlock(catId).toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          icon_code_point INTEGER NOT NULL,
          is_builtin INTEGER NOT NULL DEFAULT 0
        )
      ''');
      final catIds = <String, int>{};
      for (final c in DefaultCategories.all()) {
        final id = await db.insert('categories', c.toMap()..remove('id'));
        catIds[c.name] = id;
      }
      final priorityToCat = <String, String>{
        'core': 'Travel 360',
        'secondary': 'Incube',
        'rest': 'Rest',
        'exam': 'Exam',
        'skill': 'Skill',
        'meal': 'Meal',
      };
      final cols = await db.rawQuery('PRAGMA table_info(blocks)');
      final hasCategoryId = cols.any((c) => c['name'] == 'category_id');
      if (!hasCategoryId) {
        await db.execute(
            'ALTER TABLE blocks ADD COLUMN category_id INTEGER NOT NULL DEFAULT ${catIds['Travel 360']}');
      }
      for (final entry in priorityToCat.entries) {
        await db.update(
          'blocks',
          {'category_id': catIds[entry.value]},
          where: 'priority = ?',
          whereArgs: [entry.key],
        );
      }
    }
    if (oldV < 3) {
      final cols = await db.rawQuery('PRAGMA table_info(blocks)');
      final has = (String n) => cols.any((c) => c['name'] == n);
      if (!has('days_of_week')) {
        await db.execute(
            'ALTER TABLE blocks ADD COLUMN days_of_week INTEGER NOT NULL DEFAULT 127');
      }
      if (!has('specific_date')) {
        await db.execute('ALTER TABLE blocks ADD COLUMN specific_date TEXT');
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS holidays (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS prayer_completions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          prayer TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          completed_at_minutes INTEGER,
          UNIQUE(date, prayer)
        )
      ''');
    }
    if (oldV < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          minutes_of_day INTEGER,
          amount_cents INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          category_id INTEGER NOT NULL
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)');
    }
  }

  // Categories
  Future<List<AppCategory>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'id ASC');
    return rows.map(AppCategory.fromMap).toList();
  }

  Future<int> insertCategory(AppCategory c) async {
    final db = await database;
    return db.insert('categories', c.toMap()..remove('id'));
  }

  Future<void> updateCategory(AppCategory c) async {
    final db = await database;
    await db.update('categories', c.toMap(),
        where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    final fallback = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT id FROM categories WHERE id != ? ORDER BY id ASC LIMIT 1',
            [id])) ??
        id;
    await db.update('blocks', {'category_id': fallback},
        where: 'category_id = ?', whereArgs: [id]);
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Blocks
  Future<List<Block>> getBlocks({bool activeOnly = true}) async {
    final db = await database;
    final rows = await db.query(
      'blocks',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'start_minutes ASC, order_index ASC',
    );
    return rows.map(Block.fromMap).toList();
  }

  Future<int> insertBlock(Block b) async {
    final db = await database;
    return db.insert('blocks', b.toMap()..remove('id'));
  }

  Future<void> updateBlock(Block b) async {
    final db = await database;
    await db.update('blocks', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<void> deleteBlock(int id) async {
    final db = await database;
    await db.delete('blocks', where: 'id = ?', whereArgs: [id]);
    await db.delete('completions', where: 'block_id = ?', whereArgs: [id]);
  }

  // Completions
  Future<Map<int, Completion>> getCompletionsForDate(String date) async {
    final db = await database;
    final rows =
        await db.query('completions', where: 'date = ?', whereArgs: [date]);
    return {for (final r in rows.map(Completion.fromMap)) r.blockId: r};
  }

  Future<void> setCompletion({
    required int blockId,
    required String date,
    required bool completed,
    int? completedAtMinutes,
    String? note,
  }) async {
    final db = await database;
    final existing = await db.query(
      'completions',
      where: 'block_id = ? AND date = ?',
      whereArgs: [blockId, date],
    );
    if (existing.isEmpty) {
      await db.insert('completions', {
        'block_id': blockId,
        'date': date,
        'completed': completed ? 1 : 0,
        'completed_at_minutes': completedAtMinutes,
        'note': note,
      });
    } else {
      await db.update(
        'completions',
        {
          'completed': completed ? 1 : 0,
          'completed_at_minutes': completedAtMinutes,
          if (note != null) 'note': note,
        },
        where: 'block_id = ? AND date = ?',
        whereArgs: [blockId, date],
      );
    }
  }

  Future<List<DailyStat>> getDailyStats(int days) async {
    final db = await database;
    final today = DateTime.now();
    final List<DailyStat> result = [];
    for (int i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final ds = _dateStr(d);
      final completed = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM completions WHERE date = ? AND completed = 1',
            [ds],
          )) ??
          0;
      final total = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM blocks WHERE is_active = 1',
          )) ??
          0;
      result.add(DailyStat(date: d, completed: completed, total: total));
    }
    return result;
  }

  Future<Map<int, int>> getPerBlockCompletionCounts(int days) async {
    final db = await database;
    final today = DateTime.now();
    final start = _dateStr(today.subtract(Duration(days: days - 1)));
    final end = _dateStr(today);
    final rows = await db.rawQuery(
      'SELECT block_id, COUNT(*) AS c FROM completions '
      'WHERE completed = 1 AND date BETWEEN ? AND ? GROUP BY block_id',
      [start, end],
    );
    return {for (final r in rows) r['block_id'] as int: r['c'] as int};
  }

  // Holidays
  Future<List<Holiday>> getHolidays() async {
    final db = await database;
    final rows = await db.query('holidays', orderBy: 'date DESC');
    return rows.map(Holiday.fromMap).toList();
  }

  Future<Holiday?> getHolidayForDate(String date) async {
    final db = await database;
    final rows =
        await db.query('holidays', where: 'date = ?', whereArgs: [date]);
    return rows.isEmpty ? null : Holiday.fromMap(rows.first);
  }

  Future<int> insertHoliday(Holiday h) async {
    final db = await database;
    return db.insert('holidays', h.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHoliday(int id) async {
    final db = await database;
    await db.delete('holidays', where: 'id = ?', whereArgs: [id]);
  }

  // Prayer completions
  Future<Map<String, PrayerCompletion>> getPrayerCompletions(
      String date) async {
    final db = await database;
    final rows = await db
        .query('prayer_completions', where: 'date = ?', whereArgs: [date]);
    return {
      for (final r in rows.map(PrayerCompletion.fromMap)) r.prayer: r,
    };
  }

  Future<void> setPrayerCompletion({
    required String date,
    required String prayer,
    required bool completed,
    int? completedAtMinutes,
  }) async {
    final db = await database;
    final existing = await db.query('prayer_completions',
        where: 'date = ? AND prayer = ?', whereArgs: [date, prayer]);
    if (existing.isEmpty) {
      await db.insert('prayer_completions', {
        'date': date,
        'prayer': prayer,
        'completed': completed ? 1 : 0,
        'completed_at_minutes': completedAtMinutes,
      });
    } else {
      await db.update(
        'prayer_completions',
        {
          'completed': completed ? 1 : 0,
          'completed_at_minutes': completedAtMinutes,
        },
        where: 'date = ? AND prayer = ?',
        whereArgs: [date, prayer],
      );
    }
  }

  // Expenses
  Future<List<Expense>> getExpensesForDate(String date) async {
    final db = await database;
    final rows = await db.query('expenses',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'minutes_of_day DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insertExpense(Expense e) async {
    final db = await database;
    return db.insert('expenses', e.toMap()..remove('id'));
  }

  Future<void> updateExpense(Expense e) async {
    final db = await database;
    await db.update('expenses', e.toMap(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Total spent per day (last [days] days, most recent last).
  Future<List<DailyExpense>> getDailyExpenseTotals(int days) async {
    final db = await database;
    final today = DateTime.now();
    final List<DailyExpense> result = [];
    for (int i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final ds = _dateStr(d);
      final sum = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COALESCE(SUM(amount_cents), 0) FROM expenses WHERE date = ?',
              [ds])) ??
          0;
      result.add(DailyExpense(date: d, amountCents: sum));
    }
    return result;
  }

  Future<int> getMonthTotalCents(DateTime month) async {
    final db = await database;
    final y = month.year.toString().padLeft(4, '0');
    final m = month.month.toString().padLeft(2, '0');
    final prefix = '$y-$m';
    return Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COALESCE(SUM(amount_cents), 0) FROM expenses WHERE date LIKE '$prefix-%'",
            [])) ??
        0;
  }

  Future<Map<int, int>> getExpensesByCategoryForMonth(
      DateTime month) async {
    final db = await database;
    final y = month.year.toString().padLeft(4, '0');
    final m = month.month.toString().padLeft(2, '0');
    final prefix = '$y-$m';
    final rows = await db.rawQuery(
        "SELECT category_id, SUM(amount_cents) AS s FROM expenses WHERE date LIKE '$prefix-%' GROUP BY category_id");
    return {
      for (final r in rows)
        r['category_id'] as int: (r['s'] as int?) ?? 0,
    };
  }

  static String _dateStr(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}

class DailyStat {
  final DateTime date;
  final int completed;
  final int total;
  DailyStat(
      {required this.date, required this.completed, required this.total});
  double get pct => total == 0 ? 0 : completed / total;
}

class DailyExpense {
  final DateTime date;
  final int amountCents;
  DailyExpense({required this.date, required this.amountCents});
  double get amount => amountCents / 100.0;
}

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/block.dart';
import '../models/category.dart';
import '../models/completion.dart';
import '../models/expense.dart';
import '../models/holiday.dart';
import '../models/prayer.dart';
import '../models/qada.dart';
import '../models/todo.dart';
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
      version: 8,
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
        is_builtin INTEGER NOT NULL DEFAULT 0,
        kind TEXT NOT NULL DEFAULT 'routine'
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
        skipped INTEGER NOT NULL DEFAULT 0,
        override_start INTEGER,
        override_end INTEGER,
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
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE qada (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prayer TEXT NOT NULL,
        missed_date TEXT NOT NULL,
        made_up INTEGER NOT NULL DEFAULT 0,
        made_up_date TEXT,
        UNIQUE(prayer, missed_date)
      )
    ''');

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
    if (oldV < 5) {
      final cols = await db.rawQuery('PRAGMA table_info(categories)');
      final hasKind = cols.any((c) => c['name'] == 'kind');
      if (!hasKind) {
        await db.execute(
            "ALTER TABLE categories ADD COLUMN kind TEXT NOT NULL DEFAULT 'routine'");
      }
      // Insert default expense categories
      for (final c in DefaultCategories.allExpense()) {
        await db.insert('categories', c.toMap()..remove('id'));
      }
    }
    if (oldV < 6) {
      final cols = await db.rawQuery('PRAGMA table_info(completions)');
      final hasSkipped = cols.any((c) => c['name'] == 'skipped');
      if (!hasSkipped) {
        await db.execute(
            'ALTER TABLE completions ADD COLUMN skipped INTEGER NOT NULL DEFAULT 0');
      }
    }
    if (oldV < 7) {
      final cols = await db.rawQuery('PRAGMA table_info(completions)');
      final has = (String n) => cols.any((c) => c['name'] == n);
      if (!has('override_start')) {
        await db.execute(
            'ALTER TABLE completions ADD COLUMN override_start INTEGER');
      }
      if (!has('override_end')) {
        await db.execute(
            'ALTER TABLE completions ADD COLUMN override_end INTEGER');
      }
    }
    if (oldV < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS todos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          completed_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS qada (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          prayer TEXT NOT NULL,
          missed_date TEXT NOT NULL,
          made_up INTEGER NOT NULL DEFAULT 0,
          made_up_date TEXT,
          UNIQUE(prayer, missed_date)
        )
      ''');
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
    final rows = await db.query('categories',
        where: 'id = ?', whereArgs: [id], limit: 1);
    final kind = rows.isEmpty
        ? 'routine'
        : (rows.first['kind'] as String? ?? 'routine');
    final fallback = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT id FROM categories WHERE id != ? AND kind = ? ORDER BY id ASC LIMIT 1',
            [id, kind])) ??
        id;
    await db.update('blocks', {'category_id': fallback},
        where: 'category_id = ?', whereArgs: [id]);
    await db.update('expenses', {'category_id': fallback},
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

  Future<void> setTimeOverride({
    required int blockId,
    required String date,
    required int? startMinutes,
    required int? endMinutes,
  }) async {
    final db = await database;
    final existing = await db.query('completions',
        where: 'block_id = ? AND date = ?', whereArgs: [blockId, date]);
    if (existing.isEmpty) {
      await db.insert('completions', {
        'block_id': blockId,
        'date': date,
        'completed': 0,
        'skipped': 0,
        'override_start': startMinutes,
        'override_end': endMinutes,
      });
    } else {
      await db.update(
        'completions',
        {
          'override_start': startMinutes,
          'override_end': endMinutes,
        },
        where: 'block_id = ? AND date = ?',
        whereArgs: [blockId, date],
      );
    }
  }

  Future<void> setSkipped({
    required int blockId,
    required String date,
    required bool skipped,
  }) async {
    final db = await database;
    final existing = await db.query('completions',
        where: 'block_id = ? AND date = ?', whereArgs: [blockId, date]);
    if (existing.isEmpty) {
      await db.insert('completions', {
        'block_id': blockId,
        'date': date,
        'completed': 0,
        'skipped': skipped ? 1 : 0,
      });
    } else {
      await db.update(
        'completions',
        {'skipped': skipped ? 1 : 0},
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

  // Todos
  Future<List<Todo>> getActiveTodos() async {
    final db = await database;
    final rows = await db.query('todos',
        where: 'completed = 0', orderBy: 'id DESC');
    return rows.map(Todo.fromMap).toList();
  }

  Future<List<Todo>> getCompletedTodos({int limit = 20}) async {
    final db = await database;
    final rows = await db.query('todos',
        where: 'completed = 1',
        orderBy: 'completed_at DESC',
        limit: limit);
    return rows.map(Todo.fromMap).toList();
  }

  Future<int> insertTodo(Todo t) async {
    final db = await database;
    return db.insert('todos', t.toMap()..remove('id'));
  }

  Future<void> toggleTodo(int id, bool completed) async {
    final db = await database;
    await db.update(
      'todos',
      {
        'completed': completed ? 1 : 0,
        'completed_at': completed ? _dateStr(DateTime.now()) : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // Qada (missed prayers) — check from installDate to yesterday, batch insert
  Future<void> checkAndInsertQadaRange(
      String installDate, DateTime today) async {
    final db = await database;
    final install = DateTime.parse(installDate);
    final yesterday = today.subtract(const Duration(days: 1));
    if (yesterday.isBefore(install)) return;

    // Pre-fetch all completed prayers in the range
    final startStr = _dateStr(install);
    final endStr = _dateStr(yesterday);
    final allCompletions = await db.rawQuery(
        'SELECT date, prayer FROM prayer_completions '
        'WHERE date BETWEEN ? AND ? AND completed = 1',
        [startStr, endStr]);
    final doneSet = <String>{};
    for (final r in allCompletions) {
      doneSet.add('${r['date']}|${r['prayer']}');
    }

    // Chunked batch insert missing prayers
    const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    var cursor = install;
    while (!cursor.isAfter(yesterday)) {
      final batch = db.batch();
      var count = 0;
      while (!cursor.isAfter(yesterday) && count < 500) {
        final ds = _dateStr(cursor);
        for (final p in prayers) {
          if (!doneSet.contains('$ds|$p')) {
            batch.insert(
              'qada',
              {'prayer': p, 'missed_date': ds, 'made_up': 0},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
        cursor = cursor.add(const Duration(days: 1));
        count++;
      }
      await batch.commit(noResult: true);
    }
  }

  /// Returns only the first [limit] pending qada (for UI display).
  Future<List<Qada>> getPendingQada({int limit = 50}) async {
    final db = await database;
    final rows = await db.query('qada',
        where: 'made_up = 0',
        orderBy: 'missed_date ASC, prayer ASC',
        limit: limit);
    return rows.map(Qada.fromMap).toList();
  }

  Future<void> markQadaDone(int id) async {
    final db = await database;
    // Get the qada record to also update prayer_completions
    final rows = await db.query('qada', where: 'id = ?', whereArgs: [id]);
    await db.update(
      'qada',
      {'made_up': 1, 'made_up_date': _dateStr(DateTime.now())},
      where: 'id = ?',
      whereArgs: [id],
    );
    // Mark in prayer_completions too so calendar reflects it
    if (rows.isNotEmpty) {
      final q = rows.first;
      final date = q['missed_date'] as String;
      final prayer = q['prayer'] as String;
      final existing = await db.query('prayer_completions',
          where: 'date = ? AND prayer = ?', whereArgs: [date, prayer]);
      if (existing.isEmpty) {
        await db.insert('prayer_completions', {
          'date': date,
          'prayer': prayer,
          'completed': 1,
          'completed_at_minutes': null,
        });
      } else {
        await db.update('prayer_completions', {'completed': 1},
            where: 'date = ? AND prayer = ?', whereArgs: [date, prayer]);
      }
    }
  }

  Future<void> markQadaByDatePrayer(String date, String prayer) async {
    final db = await database;
    await db.update(
      'qada',
      {'made_up': 1, 'made_up_date': _dateStr(DateTime.now())},
      where: 'missed_date = ? AND prayer = ? AND made_up = 0',
      whereArgs: [date, prayer],
    );
    // Also mark in prayer_completions
    final existing = await db.query('prayer_completions',
        where: 'date = ? AND prayer = ?', whereArgs: [date, prayer]);
    if (existing.isEmpty) {
      await db.insert('prayer_completions', {
        'date': date,
        'prayer': prayer,
        'completed': 1,
      });
    } else {
      await db.update('prayer_completions', {'completed': 1},
          where: 'date = ? AND prayer = ?', whereArgs: [date, prayer]);
    }
  }

  Future<void> undoQadaMadeUp(int id) async {
    final db = await database;
    await db.update(
      'qada',
      {'made_up': 0, 'made_up_date': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addManualQada(String date, List<String> prayers) async {
    final db = await database;
    final batch = db.batch();
    for (final p in prayers) {
      batch.insert(
        'qada',
        {'prayer': p, 'missed_date': date, 'made_up': 0},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> addBulkQadaRange(
      String fromDate, String toDate, List<String> prayers) async {
    final db = await database;
    final from = DateTime.parse(fromDate);
    final to = DateTime.parse(toDate);
    // Chunk into batches of 500 days to avoid OOM / ANR
    var cursor = from;
    while (!cursor.isAfter(to)) {
      final batch = db.batch();
      var count = 0;
      while (!cursor.isAfter(to) && count < 500) {
        final ds = _dateStr(cursor);
        for (final p in prayers) {
          batch.insert(
            'qada',
            {'prayer': p, 'missed_date': ds, 'made_up': 0},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        cursor = cursor.add(const Duration(days: 1));
        count++;
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> resetAllData() async {
    final db = await database;
    final tables = [
      'categories', 'blocks', 'completions', 'holidays',
      'prayer_completions', 'expenses', 'todos', 'qada',
    ];
    for (final t in tables) {
      await db.delete(t);
    }
  }

  Future<int> pendingQadaCount() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM qada WHERE made_up = 0')) ??
        0;
  }

  /// Prayer calendar: date → {prayer: status}
  /// Status: 'done' = completed on time, 'missed' = not done, 'madeup' = qada made up
  Future<Map<String, Map<String, String>>> getPrayerCalendar(
      int year, int month) async {
    final db = await database;
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    // Prayer completions
    final rows = await db.rawQuery(
        "SELECT date, prayer, completed FROM prayer_completions WHERE date LIKE '$prefix-%'");
    final result = <String, Map<String, String>>{};
    for (final r in rows) {
      final d = r['date'] as String;
      final p = r['prayer'] as String;
      final c = (r['completed'] as int) == 1;
      result.putIfAbsent(d, () => {});
      result[d]![p] = c ? 'done' : 'missed';
    }
    // Overlay Qada made-up status
    final qadaRows = await db.rawQuery(
        "SELECT missed_date, prayer, made_up FROM qada WHERE missed_date LIKE '$prefix-%'");
    for (final r in qadaRows) {
      final d = r['missed_date'] as String;
      final p = r['prayer'] as String;
      final madeUp = (r['made_up'] as int) == 1;
      result.putIfAbsent(d, () => {});
      if (madeUp && result[d]![p] != 'done') {
        result[d]![p] = 'madeup';
      } else if (!madeUp && result[d]?[p] == null) {
        result[d]![p] = 'missed';
      }
    }
    return result;
  }

  /// Qada stats: pending per prayer, total pending, total made up
  Future<Map<String, int>> getQadaStats() async {
    final db = await database;
    final pending = await db.rawQuery(
        'SELECT prayer, COUNT(*) AS c FROM qada WHERE made_up = 0 GROUP BY prayer');
    final madeUp = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM qada WHERE made_up = 1')) ??
        0;
    final totalPending = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM qada WHERE made_up = 0')) ??
        0;
    final result = <String, int>{
      'total_pending': totalPending,
      'total_made_up': madeUp,
    };
    for (final r in pending) {
      result[r['prayer'] as String] = r['c'] as int;
    }
    return result;
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

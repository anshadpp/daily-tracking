import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/block.dart';
import '../models/completion.dart';
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
      version: 1,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE blocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        start_minutes INTEGER NOT NULL,
        end_minutes INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        priority TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        notify INTEGER NOT NULL DEFAULT 1
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

    final batch = db.batch();
    for (final b in defaultBlocks) {
      batch.insert('blocks', b.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  // Blocks
  Future<List<Block>> getBlocks({bool activeOnly = true}) async {
    final db = await database;
    final rows = await db.query(
      'blocks',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'order_index ASC',
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
    final rows = await db.query('completions', where: 'date = ?', whereArgs: [date]);
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

  /// Returns map of date -> {done, total} for last [days] days (inclusive of today).
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
  DailyStat({required this.date, required this.completed, required this.total});
  double get pct => total == 0 ? 0 : completed / total;
}

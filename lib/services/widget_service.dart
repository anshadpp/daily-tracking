import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/block.dart';
import '../models/category.dart';
import '../models/prayer.dart';
import '../models/todo.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const _providerClass =
      'com.example.daily_tracker.DailyTrackerWidgetProvider';
  static const _groupId = 'com.example.daily_tracker.widget';

  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_groupId);
      await HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
    } catch (e) {
      debugPrint('WidgetService.init failed: $e');
    }
  }

  Future<void> push({
    required int completed,
    required int total,
    required List<Block> todayBlocks,
    required Set<int> completedIds,
    required List<Todo> todos,
    Block? currentBlock,
    AppCategory? currentCategory,
    String? nextTitle,
    DateTime? nextTime,
    List<PrayerInstance> prayers = const [],
    int prayersDone = 0,
  }) async {
    try {
      final pct = total == 0 ? 0 : (100 * completed / total).round();

      await HomeWidget.saveWidgetData<String>(
          'headline', currentBlock?.title ?? nextTitle ?? 'All caught up');
      await HomeWidget.saveWidgetData<String>(
        'subline',
        currentBlock != null
            ? '${currentBlock.rangeLabel}  •  NOW'
            : (nextTime != null
                ? 'Up next · ${DateFormat('HH:mm').format(nextTime)}'
                : 'Great work today'),
      );
      await HomeWidget.saveWidgetData<int>('progress', pct);
      await HomeWidget.saveWidgetData<String>(
          'progressLabel', '$completed / $total');

      final scheduleJson = jsonEncode({
        'blocks': todayBlocks
            .map((b) => {
                  'id': b.id,
                  'title': b.title,
                  'start': b.startMinutes,
                  'end': b.endMinutes,
                })
            .toList(),
        'completedIds': completedIds.toList(),
        'totalBlocks': todayBlocks.length,
        'prayersDone': prayersDone,
        'prayersTotal': prayers.length,
      });
      await HomeWidget.saveWidgetData<String>('schedule', scheduleJson);

      // Save todos (first 3 active) for widget display
      final todosJson = jsonEncode(
        todos.take(3).map((t) => {'id': t.id, 'title': t.title}).toList(),
      );
      await HomeWidget.saveWidgetData<String>('todos', todosJson);

      final now = DateTime.now();
      final upcoming =
          prayers.where((p) => p.time.isAfter(now)).take(3).toList();
      await HomeWidget.saveWidgetData<String>(
        'prayers',
        upcoming
            .map((p) =>
                '${p.name.label}|${DateFormat('HH:mm').format(p.time)}')
            .join(';'),
      );

      // Qada status: prayers whose window passed and not completed
      final qadaNow = prayers
          .where((p) => p.isQadaNow)
          .map((p) => p.name.label)
          .toList();
      await HomeWidget.saveWidgetData<String>(
          'qada', qadaNow.isEmpty ? '' : qadaNow.join(', '));

      await HomeWidget.updateWidget(
        qualifiedAndroidName: _providerClass,
      );
    } catch (e) {
      debugPrint('WidgetService.push failed: $e');
    }
  }

  Future<Uri?> launchedFrom() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint('WidgetService.launchedFrom failed: $e');
      return null;
    }
  }

  Stream<Uri?> get onLaunch => HomeWidget.widgetClicked;
}

/// Runs in a background isolate when the widget fires a background intent.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (uri.host == 'toggle-todo') {
      final id = int.tryParse(uri.pathSegments.firstOrNull ?? '');
      if (id == null) return;
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(p.join(dbPath, 'daily_tracker.db'));
      final now = DateTime.now();
      final dateStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      // Toggle
      final rows =
          await db.query('todos', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final current = (rows.first['completed'] as int) == 1;
        await db.update(
          'todos',
          {
            'completed': current ? 0 : 1,
            'completed_at': current ? null : dateStr,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      // Update widget data: re-read active todos
      final active = await db.query('todos',
          where: 'completed = 0', orderBy: 'id DESC', limit: 3);
      final todosJson = jsonEncode(
        active
            .map((r) => {'id': r['id'] as int, 'title': r['title'] as String})
            .toList(),
      );
      await HomeWidget.saveWidgetData<String>('todos', todosJson);
      await db.close();
      await HomeWidget.updateWidget(
        qualifiedAndroidName:
            'com.example.daily_tracker.DailyTrackerWidgetProvider',
      );
    } else if (uri.host == 'toggle-current') {
      final dbPath = await getDatabasesPath();
      final db = await openDatabase(p.join(dbPath, 'daily_tracker.db'));
      final now = DateTime.now();
      final nowMin = now.hour * 60 + now.minute;
      final dateStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final blocks = await db.query('blocks',
          where: 'is_active = 1', orderBy: 'start_minutes ASC');
      int? currentBlockId;
      for (final b in blocks) {
        final start = b['start_minutes'] as int;
        final end = b['end_minutes'] as int;
        if (nowMin >= start && nowMin < end) {
          currentBlockId = b['id'] as int;
          break;
        }
      }
      if (currentBlockId != null) {
        final existing = await db.query('completions',
            where: 'block_id = ? AND date = ?',
            whereArgs: [currentBlockId, dateStr]);
        if (existing.isEmpty) {
          await db.insert('completions', {
            'block_id': currentBlockId,
            'date': dateStr,
            'completed': 1,
            'completed_at_minutes': nowMin,
            'skipped': 0,
          });
        } else {
          final cur = (existing.first['completed'] as int) == 1;
          await db.update('completions', {'completed': cur ? 0 : 1},
              where: 'block_id = ? AND date = ?',
              whereArgs: [currentBlockId, dateStr]);
        }
      }
      // Re-compute schedule for widget
      final allCompletions = await db.query('completions',
          where: 'date = ? AND completed = 1', whereArgs: [dateStr]);
      final doneIds = allCompletions
          .map((r) => r['block_id'] as int)
          .toList();
      final scheduleJson = jsonEncode({
        'blocks': blocks
            .map((b) => {
                  'id': b['id'] as int,
                  'title': b['title'] as String,
                  'start': b['start_minutes'] as int,
                  'end': b['end_minutes'] as int,
                })
            .toList(),
        'completedIds': doneIds,
        'totalBlocks': blocks.length,
      });
      await HomeWidget.saveWidgetData<String>('schedule', scheduleJson);
      await db.close();
      await HomeWidget.updateWidget(
        qualifiedAndroidName:
            'com.example.daily_tracker.DailyTrackerWidgetProvider',
      );
    }
  } catch (e) {
    debugPrint('widgetBackgroundCallback error: $e');
  }
}

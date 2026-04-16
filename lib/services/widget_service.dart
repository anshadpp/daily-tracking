import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/block.dart';
import '../models/category.dart';
import '../models/prayer.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const _providerClass =
      'com.example.daily_tracker.DailyTrackerWidgetProvider';
  static const _groupId = 'com.example.daily_tracker.widget';

  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_groupId);
    } catch (e) {
      debugPrint('WidgetService.init setAppGroupId failed: $e');
    }
  }

  Future<void> push({
    required int completed,
    required int total,
    required List<Block> todayBlocks,
    required Set<int> completedIds,
    Block? currentBlock,
    AppCategory? currentCategory,
    String? nextTitle,
    DateTime? nextTime,
    List<PrayerInstance> prayers = const [],
    int prayersDone = 0,
  }) async {
    try {
      final pct = total == 0 ? 0 : (100 * completed / total).round();

      // Live computed fields (for immediate display)
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

      // Full schedule JSON so widget can self-compute on periodic refresh
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

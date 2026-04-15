import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/block.dart';
import '../models/category.dart';
import '../models/prayer.dart';

class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const _groupId = 'com.example.daily_tracker.widget';
  static const _providerName = 'DailyTrackerWidgetProvider';
  static const _androidName = 'DailyTrackerWidgetProvider';
  static const _iosName = 'DailyTrackerWidget';

  Future<void> init() async {
    await HomeWidget.setAppGroupId(_groupId);
  }

  Future<void> push({
    required int completed,
    required int total,
    Block? currentBlock,
    AppCategory? currentCategory,
    String? nextTitle,
    DateTime? nextTime,
    List<PrayerInstance> prayers = const [],
  }) async {
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
    await HomeWidget.saveWidgetData<String>('progressLabel', '$completed / $total');
    await HomeWidget.saveWidgetData<int>(
        'accentColor',
        (currentCategory?.color.value ?? 0xFF2E7D32) & 0xFFFFFFFF);
    await HomeWidget.saveWidgetData<int>(
        'currentBlockId', currentBlock?.id ?? -1);

    // Next 3 prayers (by today's times)
    final now = DateTime.now();
    final upcoming = prayers
        .where((p) => p.time.isAfter(now))
        .take(3)
        .toList();
    await HomeWidget.saveWidgetData<String>(
      'prayers',
      upcoming
          .map((p) => '${p.name.label}|${DateFormat('HH:mm').format(p.time)}')
          .join(';'),
    );

    await HomeWidget.updateWidget(
      name: _androidName,
      androidName: _providerName,
      iOSName: _iosName,
    );
  }

  /// Check if app launched from widget tap and return which block to toggle.
  Future<Uri?> launchedFrom() async {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  Stream<Uri?> get onLaunch => HomeWidget.widgetClicked;
}

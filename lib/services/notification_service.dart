import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/block.dart';
import '../models/category.dart';
import '../models/prayer.dart';
import 'prayer_service.dart';
import 'settings_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
    _initialized = true;
  }

  Future<void> rescheduleAll(
      List<Block> blocks, Map<int, AppCategory> categoriesById) async {
    await init();
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);

    for (final b in blocks) {
      if (!b.isActive || !b.notify || b.id == null) continue;
      if (b.isEvent && b.specificDate != null) {
        final d = DateTime.parse(b.specificDate!);
        final fire = tz.TZDateTime(tz.local, d.year, d.month, d.day,
            b.startMinutes ~/ 60, b.startMinutes % 60);
        if (fire.isBefore(now)) continue;
        await _schedule(
          id: b.id!,
          title: b.title,
          body: b.rangeLabel +
              (b.description.isEmpty ? '' : ' • ${b.description}'),
          fire: fire,
          color: categoriesById[b.categoryId]?.color,
          repeatDaily: false,
          big: b.description,
        );
        continue;
      }

      final h = b.startMinutes ~/ 60;
      final m = b.startMinutes % 60;
      var first =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (first.isBefore(now)) first = first.add(const Duration(days: 1));
      await _schedule(
        id: b.id!,
        title: b.title,
        body: b.rangeLabel +
            (b.description.isEmpty ? '' : ' • ${b.description}'),
        fire: first,
        color: categoriesById[b.categoryId]?.color,
        repeatDaily: true,
        big: b.description,
      );
    }

    if (AppSettings.I.prayerEnabled && AppSettings.I.prayerReminders) {
      final today = PrayerService.instance.forDate(DateTime.now());
      final tomorrow = PrayerService.instance
          .forDate(DateTime.now().add(const Duration(days: 1)));
      int id = 100000;
      const prayerColor = Color(0xFF00695C);
      for (final p in [...today, ...tomorrow]) {
        final fire = tz.TZDateTime(
          tz.local,
          p.time.year,
          p.time.month,
          p.time.day,
          p.time.hour,
          p.time.minute,
        );
        if (fire.isAfter(now)) {
          await _schedule(
            id: id++,
            title: '🕌 ${p.name.label}',
            body:
                'Prayer time — ${p.timeLabel}  •  ${AppSettings.I.city}',
            fire: fire,
            color: prayerColor,
            repeatDaily: false,
            big: 'Time for ${p.name.label} prayer',
          );
        }
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime fire,
    required Color? color,
    required bool repeatDaily,
    required String big,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'block_reminders',
        'Block reminders',
        channelDescription: 'Alerts at the start of every schedule block',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        ticker: title,
        color: color,
        colorized: color != null,
        styleInformation: BigTextStyleInformation(
          big.isEmpty ? body : '$body\n$big',
          contentTitle: title,
        ),
      ),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      fire,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          repeatDaily ? DateTimeComponents.time : null,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}

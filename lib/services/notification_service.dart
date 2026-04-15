import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/block.dart' hide Priority;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
    _initialized = true;
  }

  Future<void> rescheduleAll(List<Block> blocks) async {
    await init();
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'block_reminders',
        'Block reminders',
        channelDescription: 'Reminders at the start of each schedule block',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    final now = tz.TZDateTime.now(tz.local);
    for (final b in blocks) {
      if (!b.isActive || !b.notify || b.id == null) continue;
      final h = b.startMinutes ~/ 60;
      final m = b.startMinutes % 60;
      var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (first.isBefore(now)) first = first.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        b.id!,
        b.title,
        b.rangeLabel + (b.description.isEmpty ? '' : ' • ${b.description}'),
        first,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}

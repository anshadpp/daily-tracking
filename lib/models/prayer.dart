import 'package:flutter/material.dart';

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

extension PrayerNameX on PrayerName {
  String get label {
    switch (this) {
      case PrayerName.fajr:
        return 'Fajr';
      case PrayerName.dhuhr:
        return 'Dhuhr';
      case PrayerName.asr:
        return 'Asr';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isha:
        return 'Isha';
    }
  }

  String get key => name;

  IconData get icon {
    switch (this) {
      case PrayerName.fajr:
        return Icons.wb_twilight_rounded;
      case PrayerName.dhuhr:
        return Icons.wb_sunny_rounded;
      case PrayerName.asr:
        return Icons.wb_cloudy_rounded;
      case PrayerName.maghrib:
        return Icons.wb_shade_rounded;
      case PrayerName.isha:
        return Icons.nights_stay_rounded;
    }
  }
}

class PrayerInstance {
  final PrayerName name;
  final DateTime time;
  final bool completed;
  PrayerInstance({required this.name, required this.time, this.completed = false});

  int get minutesFromMidnight => time.hour * 60 + time.minute;

  String get timeLabel {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class PrayerCompletion {
  final int? id;
  final String date; // YYYY-MM-DD
  final String prayer; // fajr, dhuhr, ...
  final bool completed;
  final int? completedAtMinutes;

  PrayerCompletion({
    this.id,
    required this.date,
    required this.prayer,
    required this.completed,
    this.completedAtMinutes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'prayer': prayer,
        'completed': completed ? 1 : 0,
        'completed_at_minutes': completedAtMinutes,
      };

  factory PrayerCompletion.fromMap(Map<String, dynamic> m) => PrayerCompletion(
        id: m['id'] as int?,
        date: m['date'] as String,
        prayer: m['prayer'] as String,
        completed: (m['completed'] as int) == 1,
        completedAtMinutes: m['completed_at_minutes'] as int?,
      );
}

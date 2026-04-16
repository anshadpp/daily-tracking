import 'package:adhan/adhan.dart';

import '../models/prayer.dart';
import 'settings_service.dart';

class PrayerService {
  PrayerService._();
  static final PrayerService instance = PrayerService._();

  CalculationParameters _params(String method, String asr) {
    CalculationParameters p;
    switch (method) {
      case 'Egyptian':
        p = CalculationMethod.egyptian.getParameters();
        break;
      case 'Karachi':
        p = CalculationMethod.karachi.getParameters();
        break;
      case 'UmmAlQura':
        p = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'Dubai':
        p = CalculationMethod.dubai.getParameters();
        break;
      case 'MoonsightingCommittee':
        p = CalculationMethod.moon_sighting_committee.getParameters();
        break;
      case 'NorthAmerica':
        p = CalculationMethod.north_america.getParameters();
        break;
      case 'Kuwait':
        p = CalculationMethod.kuwait.getParameters();
        break;
      case 'Qatar':
        p = CalculationMethod.qatar.getParameters();
        break;
      case 'Singapore':
        p = CalculationMethod.singapore.getParameters();
        break;
      case 'Turkey':
        p = CalculationMethod.turkey.getParameters();
        break;
      case 'Tehran':
        p = CalculationMethod.tehran.getParameters();
        break;
      case 'MuslimWorldLeague':
      default:
        p = CalculationMethod.muslim_world_league.getParameters();
    }
    p.madhab = asr == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    return p;
  }

  /// Returns prayer instances with Islamic deadlines:
  /// - Fajr: starts at fajr, deadline = sunrise
  /// - Dhuhr: starts at dhuhr, deadline = asr
  /// - Asr: starts at asr, deadline = maghrib (sunset)
  /// - Maghrib: starts at maghrib, deadline = isha
  /// - Isha: starts at isha, deadline = next day's fajr
  List<PrayerInstance> forDate(DateTime date) {
    final s = AppSettings.I;
    final coords = Coordinates(s.latitude, s.longitude);
    final params = _params(s.method, s.asrJuristic);
    final dateComps = DateComponents.from(date);
    final times = PrayerTimes(coords, dateComps, params);

    // Get next day's fajr for isha deadline
    final nextDay = date.add(const Duration(days: 1));
    final nextComps = DateComponents.from(nextDay);
    final nextTimes = PrayerTimes(coords, nextComps, params);

    return [
      PrayerInstance(
        name: PrayerName.fajr,
        time: times.fajr.toLocal(),
        deadline: times.sunrise.toLocal(), // Fajr → Qada at sunrise
      ),
      PrayerInstance(
        name: PrayerName.dhuhr,
        time: times.dhuhr.toLocal(),
        deadline: times.asr.toLocal(), // Dhuhr → Qada at Asr
      ),
      PrayerInstance(
        name: PrayerName.asr,
        time: times.asr.toLocal(),
        deadline: times.maghrib.toLocal(), // Asr → Qada at Maghrib
      ),
      PrayerInstance(
        name: PrayerName.maghrib,
        time: times.maghrib.toLocal(),
        deadline: times.isha.toLocal(), // Maghrib → Qada at Isha
      ),
      PrayerInstance(
        name: PrayerName.isha,
        time: times.isha.toLocal(),
        deadline: nextTimes.fajr.toLocal(), // Isha → Qada at next Fajr
      ),
    ];
  }

  /// Get sunrise time for a given date (used in widget/notification)
  DateTime sunriseFor(DateTime date) {
    final s = AppSettings.I;
    final coords = Coordinates(s.latitude, s.longitude);
    final params = _params(s.method, s.asrJuristic);
    final times = PrayerTimes(coords, DateComponents.from(date), params);
    return times.sunrise.toLocal();
  }

  static const methodChoices = [
    'MuslimWorldLeague',
    'Egyptian',
    'Karachi',
    'UmmAlQura',
    'Dubai',
    'Qatar',
    'Kuwait',
    'Singapore',
    'Turkey',
    'Tehran',
    'NorthAmerica',
    'MoonsightingCommittee',
  ];
}

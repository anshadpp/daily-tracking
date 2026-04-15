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

  List<PrayerInstance> forDate(DateTime date) {
    final s = AppSettings.I;
    final coords = Coordinates(s.latitude, s.longitude);
    final params = _params(s.method, s.asrJuristic);
    final dateComps = DateComponents.from(date);
    final times = PrayerTimes(coords, dateComps, params);
    return [
      PrayerInstance(name: PrayerName.fajr, time: times.fajr.toLocal()),
      PrayerInstance(name: PrayerName.dhuhr, time: times.dhuhr.toLocal()),
      PrayerInstance(name: PrayerName.asr, time: times.asr.toLocal()),
      PrayerInstance(name: PrayerName.maghrib, time: times.maghrib.toLocal()),
      PrayerInstance(name: PrayerName.isha, time: times.isha.toLocal()),
    ];
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

import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const _kLat = 'prayer_lat';
  static const _kLng = 'prayer_lng';
  static const _kCity = 'prayer_city';
  static const _kMethod = 'prayer_method';
  static const _kPrayerEnabled = 'prayer_enabled';
  static const _kPrayerReminders = 'prayer_reminders';
  static const _kAsrJuristic = 'asr_juristic';
  static const _kCurrency = 'currency_symbol';
  static const _kInstallDate = 'install_date';

  double latitude = 21.4225;
  double longitude = 39.8262;
  String city = 'Makkah';
  String method = 'MuslimWorldLeague';
  bool prayerEnabled = true;
  bool prayerReminders = true;
  String asrJuristic = 'standard';
  String currencySymbol = '₹';
  String? installDate; // YYYY-MM-DD, set on first run
  bool locationPicked = false;
  bool onboardingDone = false;

  static final AppSettings _i = AppSettings._();
  AppSettings._();
  static AppSettings get I => _i;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    latitude = p.getDouble(_kLat) ?? latitude;
    longitude = p.getDouble(_kLng) ?? longitude;
    city = p.getString(_kCity) ?? city;
    method = p.getString(_kMethod) ?? method;
    prayerEnabled = p.getBool(_kPrayerEnabled) ?? prayerEnabled;
    prayerReminders = p.getBool(_kPrayerReminders) ?? prayerReminders;
    asrJuristic = p.getString(_kAsrJuristic) ?? asrJuristic;
    currencySymbol = p.getString(_kCurrency) ?? currencySymbol;
    installDate = p.getString(_kInstallDate);
    locationPicked = p.getBool('location_picked') ?? false;
    onboardingDone = p.getBool('onboarding_done') ?? false;
    if (installDate == null) {
      final now = DateTime.now();
      installDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await p.setString(_kInstallDate, installDate!);
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kLat, latitude);
    await p.setDouble(_kLng, longitude);
    await p.setString(_kCity, city);
    await p.setString(_kMethod, method);
    await p.setBool(_kPrayerEnabled, prayerEnabled);
    await p.setBool(_kPrayerReminders, prayerReminders);
    await p.setString(_kAsrJuristic, asrJuristic);
    await p.setString(_kCurrency, currencySymbol);
    await p.setBool('location_picked', locationPicked);
    await p.setBool('onboarding_done', onboardingDone);
  }
}

class CommonCity {
  final String name;
  final double lat;
  final double lng;
  const CommonCity(this.name, this.lat, this.lng);

  static const all = [
    CommonCity('Makkah', 21.4225, 39.8262),
    CommonCity('Madinah', 24.4672, 39.6111),
    CommonCity('Cairo', 30.0444, 31.2357),
    CommonCity('Istanbul', 41.0082, 28.9784),
    CommonCity('Riyadh', 24.7136, 46.6753),
    CommonCity('Dubai', 25.2048, 55.2708),
    CommonCity('Kuwait', 29.3759, 47.9774),
    CommonCity('Doha', 25.2854, 51.5310),
    CommonCity('Karachi', 24.8607, 67.0011),
    CommonCity('Lahore', 31.5204, 74.3587),
    CommonCity('Delhi', 28.6139, 77.2090),
    CommonCity('Mumbai', 19.0760, 72.8777),
    CommonCity('Kochi', 9.9312, 76.2673),
    CommonCity('Kozhikode', 11.2588, 75.7804),
    CommonCity('Bengaluru', 12.9716, 77.5946),
    CommonCity('Hyderabad', 17.3850, 78.4867),
    CommonCity('Dhaka', 23.8103, 90.4125),
    CommonCity('Jakarta', 6.2088 * -1, 106.8456), // south hemisphere
    CommonCity('Kuala Lumpur', 3.1390, 101.6869),
    CommonCity('London', 51.5074, -0.1278),
    CommonCity('New York', 40.7128, -74.0060),
  ];
}

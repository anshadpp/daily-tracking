class Qada {
  final int? id;
  final String prayer; // fajr, dhuhr, asr, maghrib, isha
  final String missedDate; // YYYY-MM-DD
  final bool madeUp;
  final String? madeUpDate;

  Qada({
    this.id,
    required this.prayer,
    required this.missedDate,
    this.madeUp = false,
    this.madeUpDate,
  });

  String get prayerLabel =>
      prayer[0].toUpperCase() + prayer.substring(1);

  Map<String, dynamic> toMap() => {
        'id': id,
        'prayer': prayer,
        'missed_date': missedDate,
        'made_up': madeUp ? 1 : 0,
        'made_up_date': madeUpDate,
      };

  factory Qada.fromMap(Map<String, dynamic> m) => Qada(
        id: m['id'] as int?,
        prayer: m['prayer'] as String,
        missedDate: m['missed_date'] as String,
        madeUp: (m['made_up'] as int) == 1,
        madeUpDate: m['made_up_date'] as String?,
      );
}

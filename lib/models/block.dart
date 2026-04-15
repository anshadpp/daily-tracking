class Block {
  // daysOfWeek bitmask — Monday=1 (DateTime.monday=1 .. Sunday=7 → bit = 1 << (weekday-1))
  // 127 = all days.
  final int? id;
  final String title;
  final String description;
  final int startMinutes;
  final int endMinutes;
  final int orderIndex;
  final int categoryId;
  final bool isActive;
  final bool notify;
  final int daysOfWeek;
  final String? specificDate; // YYYY-MM-DD, for one-off events

  Block({
    this.id,
    required this.title,
    required this.description,
    required this.startMinutes,
    required this.endMinutes,
    required this.orderIndex,
    required this.categoryId,
    this.isActive = true,
    this.notify = true,
    this.daysOfWeek = 127,
    this.specificDate,
  });

  bool get isEvent => specificDate != null;

  bool occursOn(DateTime date) {
    if (specificDate != null) {
      final ds = _dateStr(date);
      return specificDate == ds;
    }
    final bit = 1 << (date.weekday - 1); // Monday=1 → bit 1
    return (daysOfWeek & bit) != 0;
  }

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get startLabel => _fmt(startMinutes);
  String get endLabel => _fmt(endMinutes);
  String get rangeLabel => '$startLabel – $endLabel';
  int get durationMinutes => endMinutes - startMinutes;

  static String _fmt(int m) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'start_minutes': startMinutes,
        'end_minutes': endMinutes,
        'order_index': orderIndex,
        'category_id': categoryId,
        'is_active': isActive ? 1 : 0,
        'notify': notify ? 1 : 0,
        'days_of_week': daysOfWeek,
        'specific_date': specificDate,
      };

  factory Block.fromMap(Map<String, dynamic> m) => Block(
        id: m['id'] as int?,
        title: m['title'] as String,
        description: (m['description'] as String?) ?? '',
        startMinutes: m['start_minutes'] as int,
        endMinutes: m['end_minutes'] as int,
        orderIndex: m['order_index'] as int,
        categoryId: (m['category_id'] as int?) ?? 1,
        isActive: (m['is_active'] as int) == 1,
        notify: (m['notify'] as int? ?? 1) == 1,
        daysOfWeek: (m['days_of_week'] as int?) ?? 127,
        specificDate: m['specific_date'] as String?,
      );

  Block copyWith({
    int? id,
    String? title,
    String? description,
    int? startMinutes,
    int? endMinutes,
    int? orderIndex,
    int? categoryId,
    bool? isActive,
    bool? notify,
    int? daysOfWeek,
    Object? specificDate = _sentinel,
  }) =>
      Block(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
        orderIndex: orderIndex ?? this.orderIndex,
        categoryId: categoryId ?? this.categoryId,
        isActive: isActive ?? this.isActive,
        notify: notify ?? this.notify,
        daysOfWeek: daysOfWeek ?? this.daysOfWeek,
        specificDate: identical(specificDate, _sentinel)
            ? this.specificDate
            : specificDate as String?,
      );
}

const _sentinel = Object();

class DaysOfWeek {
  static const int all = 127; // 1111111
  static const int weekdays = 31; // Mon..Fri = 1+2+4+8+16
  static const int weekends = 96; // Sat(32)+Sun(64)
  static const int none = 0;

  static int bit(int weekday) => 1 << (weekday - 1);
  static bool has(int mask, int weekday) => (mask & bit(weekday)) != 0;

  static const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String label(int mask) {
    if (mask == all) return 'Every day';
    if (mask == weekdays) return 'Weekdays';
    if (mask == weekends) return 'Weekends';
    if (mask == 0) return 'Never';
    final picked = <String>[];
    for (int i = 1; i <= 7; i++) {
      if (has(mask, i)) picked.add(names[i - 1]);
    }
    return picked.join(', ');
  }
}

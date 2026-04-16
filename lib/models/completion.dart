class Completion {
  final int? id;
  final int blockId;
  final String date; // yyyy-MM-dd
  final bool completed;
  final int? completedAtMinutes;
  final String? note;
  final bool skipped;
  final int? overrideStart; // minutes from midnight, null = use default
  final int? overrideEnd;

  Completion({
    this.id,
    required this.blockId,
    required this.date,
    required this.completed,
    this.completedAtMinutes,
    this.note,
    this.skipped = false,
    this.overrideStart,
    this.overrideEnd,
  });

  bool get hasTimeOverride => overrideStart != null || overrideEnd != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'block_id': blockId,
        'date': date,
        'completed': completed ? 1 : 0,
        'completed_at_minutes': completedAtMinutes,
        'note': note,
        'skipped': skipped ? 1 : 0,
        'override_start': overrideStart,
        'override_end': overrideEnd,
      };

  factory Completion.fromMap(Map<String, dynamic> m) => Completion(
        id: m['id'] as int?,
        blockId: m['block_id'] as int,
        date: m['date'] as String,
        completed: (m['completed'] as int) == 1,
        completedAtMinutes: m['completed_at_minutes'] as int?,
        note: m['note'] as String?,
        skipped: (m['skipped'] as int? ?? 0) == 1,
        overrideStart: m['override_start'] as int?,
        overrideEnd: m['override_end'] as int?,
      );
}

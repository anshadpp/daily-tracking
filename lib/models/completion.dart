class Completion {
  final int? id;
  final int blockId;
  final String date; // yyyy-MM-dd
  final bool completed;
  final int? completedAtMinutes; // minutes from midnight when checked
  final String? note;

  Completion({
    this.id,
    required this.blockId,
    required this.date,
    required this.completed,
    this.completedAtMinutes,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'block_id': blockId,
        'date': date,
        'completed': completed ? 1 : 0,
        'completed_at_minutes': completedAtMinutes,
        'note': note,
      };

  factory Completion.fromMap(Map<String, dynamic> m) => Completion(
        id: m['id'] as int?,
        blockId: m['block_id'] as int,
        date: m['date'] as String,
        completed: (m['completed'] as int) == 1,
        completedAtMinutes: m['completed_at_minutes'] as int?,
        note: m['note'] as String?,
      );
}

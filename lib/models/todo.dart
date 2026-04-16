class Todo {
  final int? id;
  final String title;
  final bool completed;
  final String createdAt; // YYYY-MM-DD
  final String? completedAt; // YYYY-MM-DD

  Todo({
    this.id,
    required this.title,
    this.completed = false,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'completed': completed ? 1 : 0,
        'created_at': createdAt,
        'completed_at': completedAt,
      };

  factory Todo.fromMap(Map<String, dynamic> m) => Todo(
        id: m['id'] as int?,
        title: m['title'] as String,
        completed: (m['completed'] as int) == 1,
        createdAt: m['created_at'] as String,
        completedAt: m['completed_at'] as String?,
      );

  Todo copyWith({
    int? id,
    String? title,
    bool? completed,
    String? createdAt,
    String? completedAt,
  }) =>
      Todo(
        id: id ?? this.id,
        title: title ?? this.title,
        completed: completed ?? this.completed,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
      );
}

class Block {
  final int? id;
  final String title;
  final String description;
  final int startMinutes;
  final int endMinutes;
  final int orderIndex;
  final int categoryId;
  final bool isActive;
  final bool notify;

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
  });

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
      );
}

import 'package:flutter/material.dart';

enum Priority { core, secondary, rest, exam, skill, meal }

extension PriorityX on Priority {
  String get label {
    switch (this) {
      case Priority.core:
        return 'Travel 360 (Core)';
      case Priority.secondary:
        return 'Incube';
      case Priority.rest:
        return 'Rest';
      case Priority.exam:
        return 'Exam';
      case Priority.skill:
        return 'Skill';
      case Priority.meal:
        return 'Meal';
    }
  }

  Color get color {
    switch (this) {
      case Priority.core:
        return const Color(0xFF2E7D32);
      case Priority.secondary:
        return const Color(0xFF1565C0);
      case Priority.rest:
        return const Color(0xFF6D4C41);
      case Priority.exam:
        return const Color(0xFFC62828);
      case Priority.skill:
        return const Color(0xFF6A1B9A);
      case Priority.meal:
        return const Color(0xFFEF6C00);
    }
  }
}

class Block {
  final int? id;
  final String title;
  final String description;
  final int startMinutes; // minutes from midnight
  final int endMinutes;
  final int orderIndex;
  final Priority priority;
  final bool isActive;
  final bool notify;

  Block({
    this.id,
    required this.title,
    required this.description,
    required this.startMinutes,
    required this.endMinutes,
    required this.orderIndex,
    required this.priority,
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
        'priority': priority.name,
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
        priority: Priority.values.firstWhere(
          (p) => p.name == m['priority'],
          orElse: () => Priority.core,
        ),
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
    Priority? priority,
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
        priority: priority ?? this.priority,
        isActive: isActive ?? this.isActive,
        notify: notify ?? this.notify,
      );
}

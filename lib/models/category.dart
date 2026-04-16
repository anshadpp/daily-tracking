import 'package:flutter/material.dart';

enum CategoryKind { routine, expense }

class AppCategory {
  final int? id;
  final String name;
  final int colorValue;
  final int iconCodePoint;
  final bool isBuiltIn;
  final CategoryKind kind;

  AppCategory({
    this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    this.isBuiltIn = false,
    this.kind = CategoryKind.routine,
  });

  Color get color => Color(colorValue);
  IconData get icon =>
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color_value': colorValue,
        'icon_code_point': iconCodePoint,
        'is_builtin': isBuiltIn ? 1 : 0,
        'kind': kind.name,
      };

  factory AppCategory.fromMap(Map<String, dynamic> m) => AppCategory(
        id: m['id'] as int?,
        name: m['name'] as String,
        colorValue: m['color_value'] as int,
        iconCodePoint: m['icon_code_point'] as int,
        isBuiltIn: (m['is_builtin'] as int? ?? 0) == 1,
        kind: CategoryKind.values.firstWhere(
          (k) => k.name == (m['kind'] as String? ?? 'routine'),
          orElse: () => CategoryKind.routine,
        ),
      );

  AppCategory copyWith({
    int? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    bool? isBuiltIn,
    CategoryKind? kind,
  }) =>
      AppCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        kind: kind ?? this.kind,
      );
}

class DefaultCategories {
  static final travel360 = AppCategory(
    name: 'Travel 360',
    colorValue: 0xFF2E7D32,
    iconCodePoint: Icons.work_rounded.codePoint,
    isBuiltIn: true,
  );
  static final incube = AppCategory(
    name: 'Incube',
    colorValue: 0xFF1565C0,
    iconCodePoint: Icons.api_rounded.codePoint,
    isBuiltIn: true,
  );
  static final rest = AppCategory(
    name: 'Rest',
    colorValue: 0xFF6D4C41,
    iconCodePoint: Icons.self_improvement_rounded.codePoint,
    isBuiltIn: true,
  );
  static final exam = AppCategory(
    name: 'Exam',
    colorValue: 0xFFC62828,
    iconCodePoint: Icons.menu_book_rounded.codePoint,
    isBuiltIn: true,
  );
  static final skill = AppCategory(
    name: 'Skill',
    colorValue: 0xFF6A1B9A,
    iconCodePoint: Icons.auto_awesome_rounded.codePoint,
    isBuiltIn: true,
  );
  static final meal = AppCategory(
    name: 'Meal',
    colorValue: 0xFFEF6C00,
    iconCodePoint: Icons.restaurant_rounded.codePoint,
    isBuiltIn: true,
  );
  static final prayer = AppCategory(
    name: 'Prayer',
    colorValue: 0xFF00695C,
    iconCodePoint: Icons.mosque_rounded.codePoint,
    isBuiltIn: true,
  );
  static final hadith = AppCategory(
    name: 'Hadith',
    colorValue: 0xFF4E342E,
    iconCodePoint: Icons.menu_book_rounded.codePoint,
    isBuiltIn: true,
  );
  static final myCompany = AppCategory(
    name: 'My Company',
    colorValue: 0xFFAD1457,
    iconCodePoint: Icons.rocket_launch_rounded.codePoint,
    isBuiltIn: true,
  );
  static final event = AppCategory(
    name: 'Event',
    colorValue: 0xFF3949AB,
    iconCodePoint: Icons.event_rounded.codePoint,
    isBuiltIn: true,
  );

  // Expense categories
  static final expFood = AppCategory(
    name: 'Food',
    colorValue: 0xFFEF6C00,
    iconCodePoint: Icons.fastfood_rounded.codePoint,
    isBuiltIn: true,
    kind: CategoryKind.expense,
  );
  static final expTransport = AppCategory(
    name: 'Transport',
    colorValue: 0xFF1565C0,
    iconCodePoint: Icons.directions_bus_rounded.codePoint,
    isBuiltIn: true,
    kind: CategoryKind.expense,
  );
  static final expBills = AppCategory(
    name: 'Bills',
    colorValue: 0xFFC62828,
    iconCodePoint: Icons.receipt_long_rounded.codePoint,
    isBuiltIn: true,
    kind: CategoryKind.expense,
  );
  static final expShopping = AppCategory(
    name: 'Shopping',
    colorValue: 0xFF6A1B9A,
    iconCodePoint: Icons.shopping_bag_rounded.codePoint,
    isBuiltIn: true,
    kind: CategoryKind.expense,
  );
  static final expHealth = AppCategory(
    name: 'Health',
    colorValue: 0xFF00897B,
    iconCodePoint: Icons.favorite_rounded.codePoint,
    isBuiltIn: true,
    kind: CategoryKind.expense,
  );
  static final expRent = AppCategory(
    name: 'Rent',
    colorValue: 0xFF4E342E,
    iconCodePoint: Icons.home_rounded.codePoint,
    isBuiltIn: true,
    kind: CategoryKind.expense,
  );
  static final expOther = AppCategory(
    name: 'Other',
    colorValue: 0xFF546E7A,
    iconCodePoint: Icons.more_horiz_rounded.codePoint,
    isBuiltIn: true,
    kind: CategoryKind.expense,
  );

  // No prebuilt routine categories — user creates their own.
  static List<AppCategory> allRoutine() => [];

  static List<AppCategory> allExpense() => [
        expFood,
        expTransport,
        expBills,
        expShopping,
        expHealth,
        expRent,
        expOther,
      ];

  static List<AppCategory> all() =>
      [...allRoutine(), ...allExpense()];
}

class CategoryPalette {
  static const colors = <int>[
    0xFF2E7D32, 0xFF388E3C, 0xFF00897B, 0xFF00ACC1,
    0xFF1565C0, 0xFF3949AB, 0xFF5E35B1, 0xFF6A1B9A,
    0xFFC62828, 0xFFE53935, 0xFFEF6C00, 0xFFFB8C00,
    0xFFFDD835, 0xFF7CB342, 0xFF6D4C41, 0xFF546E7A,
  ];

  static List<IconData> icons = [
    Icons.work_rounded,
    Icons.api_rounded,
    Icons.self_improvement_rounded,
    Icons.menu_book_rounded,
    Icons.auto_awesome_rounded,
    Icons.restaurant_rounded,
    Icons.fitness_center_rounded,
    Icons.code_rounded,
    Icons.design_services_rounded,
    Icons.bedtime_rounded,
    Icons.coffee_rounded,
    Icons.directions_run_rounded,
    Icons.music_note_rounded,
    Icons.volunteer_activism_rounded,
    Icons.brush_rounded,
    Icons.headphones_rounded,
    Icons.phone_rounded,
    Icons.email_rounded,
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.local_cafe_rounded,
    Icons.sports_esports_rounded,
    Icons.school_rounded,
    Icons.psychology_rounded,
  ];
}

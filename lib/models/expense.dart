class Expense {
  final int? id;
  final String date; // YYYY-MM-DD
  final int? minutesOfDay;
  final int amountCents; // integer to avoid float precision
  final String title;
  final String? description;
  final int categoryId;

  Expense({
    this.id,
    required this.date,
    this.minutesOfDay,
    required this.amountCents,
    required this.title,
    this.description,
    required this.categoryId,
  });

  double get amount => amountCents / 100.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'minutes_of_day': minutesOfDay,
        'amount_cents': amountCents,
        'title': title,
        'description': description,
        'category_id': categoryId,
      };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'] as int?,
        date: m['date'] as String,
        minutesOfDay: m['minutes_of_day'] as int?,
        amountCents: m['amount_cents'] as int,
        title: m['title'] as String,
        description: m['description'] as String?,
        categoryId: m['category_id'] as int,
      );

  Expense copyWith({
    int? id,
    String? date,
    int? minutesOfDay,
    int? amountCents,
    String? title,
    String? description,
    int? categoryId,
  }) =>
      Expense(
        id: id ?? this.id,
        date: date ?? this.date,
        minutesOfDay: minutesOfDay ?? this.minutesOfDay,
        amountCents: amountCents ?? this.amountCents,
        title: title ?? this.title,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
      );
}

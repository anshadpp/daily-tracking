class Holiday {
  final int? id;
  final String date; // YYYY-MM-DD
  final String name;

  Holiday({this.id, required this.date, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'date': date, 'name': name};

  factory Holiday.fromMap(Map<String, dynamic> m) => Holiday(
        id: m['id'] as int?,
        date: m['date'] as String,
        name: m['name'] as String,
      );
}

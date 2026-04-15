import '../models/block.dart';

int _t(int h, int m) => h * 60 + m;

class BlockSeed {
  final String title;
  final String description;
  final int startMinutes;
  final int endMinutes;
  final int orderIndex;
  final String categoryName;
  final int daysOfWeek;

  const BlockSeed({
    required this.title,
    required this.description,
    required this.startMinutes,
    required this.endMinutes,
    required this.orderIndex,
    required this.categoryName,
    this.daysOfWeek = 127,
  });

  Block toBlock(int categoryId) => Block(
        title: title,
        description: description,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        orderIndex: orderIndex,
        categoryId: categoryId,
        daysOfWeek: daysOfWeek,
      );
}

final List<BlockSeed> defaultBlockSeeds = [
  BlockSeed(
    title: 'Wake up',
    description: 'Get up, hydrate, fresh air',
    startMinutes: _t(5, 30),
    endMinutes: _t(6, 0),
    orderIndex: 0,
    categoryName: 'Rest',
  ),
  BlockSeed(
    title: 'Travel 360 Standup',
    description: 'Be sharp — defines visibility',
    startMinutes: _t(6, 15),
    endMinutes: _t(7, 15),
    orderIndex: 1,
    categoryName: 'Travel 360',
    daysOfWeek: 31, // weekdays only
  ),
  BlockSeed(
    title: 'Deep Work — Travel 360',
    description: 'React features, Node APIs, real bugs. Best energy.',
    startMinutes: _t(7, 15),
    endMinutes: _t(10, 0),
    orderIndex: 2,
    categoryName: 'Travel 360',
  ),
  BlockSeed(
    title: 'Cooking + Breakfast',
    description: '',
    startMinutes: _t(10, 0),
    endMinutes: _t(11, 0),
    orderIndex: 3,
    categoryName: 'Meal',
  ),
  BlockSeed(
    title: 'Travel 360 Execution',
    description: 'Continue tasks, push progress, follow-ups',
    startMinutes: _t(11, 0),
    endMinutes: _t(13, 30),
    orderIndex: 4,
    categoryName: 'Travel 360',
  ),
  BlockSeed(
    title: 'Lunch + Rest',
    description: '',
    startMinutes: _t(13, 30),
    endMinutes: _t(14, 15),
    orderIndex: 5,
    categoryName: 'Meal',
  ),
  BlockSeed(
    title: 'Incube — WhatsApp / Meta API',
    description: 'Spring Boot, Meta integration. Focused but limited.',
    startMinutes: _t(14, 15),
    endMinutes: _t(16, 0),
    orderIndex: 6,
    categoryName: 'Incube',
  ),
  BlockSeed(
    title: 'Light Work',
    description: 'Bug fixes, replies, small tasks',
    startMinutes: _t(16, 0),
    endMinutes: _t(17, 0),
    orderIndex: 7,
    categoryName: 'Incube',
  ),
  BlockSeed(
    title: 'Recovery (Rest / Walk / Nap)',
    description: 'Non-negotiable. Keeps you alive mentally.',
    startMinutes: _t(17, 0),
    endMinutes: _t(18, 0),
    orderIndex: 8,
    categoryName: 'Rest',
  ),
  BlockSeed(
    title: 'Dinner',
    description: '',
    startMinutes: _t(18, 0),
    endMinutes: _t(19, 0),
    orderIndex: 9,
    categoryName: 'Meal',
  ),
  BlockSeed(
    title: 'Exam Prep',
    description: 'Important topics only',
    startMinutes: _t(19, 0),
    endMinutes: _t(20, 0),
    orderIndex: 10,
    categoryName: 'Exam',
  ),
  BlockSeed(
    title: 'Skill Upgrade — Travel 360',
    description: 'Rotate: React internals / Node perf / API design / debugging',
    startMinutes: _t(20, 0),
    endMinutes: _t(21, 0),
    orderIndex: 11,
    categoryName: 'Skill',
  ),
  BlockSeed(
    title: 'Sleep',
    description: 'Lights out',
    startMinutes: _t(21, 30),
    endMinutes: _t(22, 0),
    orderIndex: 12,
    categoryName: 'Rest',
  ),
];

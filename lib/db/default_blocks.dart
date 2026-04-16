import '../models/block.dart';

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

// No prebuilt blocks — user builds their own schedule from scratch.
final List<BlockSeed> defaultBlockSeeds = [];

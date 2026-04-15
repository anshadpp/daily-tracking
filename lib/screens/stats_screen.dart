import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database.dart';
import '../models/block.dart';
import '../providers/tracker_provider.dart';
import '../widgets/glass.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _days = 7;
  Future<_StatsBundle>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StatsBundle> _load() async {
    final daily = await AppDatabase.instance.getDailyStats(_days);
    final perBlock =
        await AppDatabase.instance.getPerBlockCompletionCounts(_days);
    return _StatsBundle(daily: daily, perBlock: perBlock);
  }

  void _setRange(int d) {
    setState(() {
      _days = d;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    final blocks = tp.blocks;
    final cats = tp.categoryById;
    return FutureBuilder<_StatsBundle>(
      future: _future,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final b = snap.data!;
        final avg = b.daily.isEmpty
            ? 0.0
            : b.daily.map((d) => d.pct).reduce((a, c) => a + c) /
                b.daily.length;
        final streak = _streak(b.daily);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
          children: [
            Wrap(
              spacing: 8,
              children: [7, 14, 30].map((d) {
                final selected = _days == d;
                return GestureDetector(
                  onTap: () => _setRange(d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      '$d d',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _statTile('Avg', '${(avg * 100).round()}%')),
                const SizedBox(width: 10),
                Expanded(child: _statTile('Streak', '$streak d')),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    'Best',
                    b.daily.isEmpty
                        ? '—'
                        : '${(b.daily.reduce((a, c) => a.pct >= c.pct ? a : c).pct * 100).round()}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Daily completion %',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Glass(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: SizedBox(height: 220, child: _barChart(b.daily)),
            ),
            const SizedBox(height: 24),
            Text('Per-block completion (last $_days days)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Glass(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (final block in _sortedBlocks(blocks, b.perBlock))
                    _perBlockRow(context, block, b.perBlock[block.id] ?? 0,
                        cats[block.categoryId]?.color),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statTile(String label, String value) {
    return Glass(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  )),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
        ],
      ),
    );
  }

  Widget _barChart(List<DailyStat> daily) {
    final cs = Theme.of(context).colorScheme;
    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        barTouchData: BarTouchData(enabled: true),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: cs.outline.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 25,
              getTitlesWidget: (v, _) =>
                  Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= daily.length) return const SizedBox();
                return Text(
                  DateFormat('d/M').format(daily[i].date),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < daily.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: daily[i].pct * 100,
                width: 10,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [cs.primary.withOpacity(0.6), cs.primary],
                ),
              ),
            ]),
        ],
      ),
    );
  }

  List<Block> _sortedBlocks(List<Block> blocks, Map<int, int> counts) {
    final list = [...blocks];
    list.sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    return list;
  }

  Widget _perBlockRow(
      BuildContext context, Block b, int count, Color? color) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final pct = _days == 0 ? 0.0 : count / _days;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(b.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text('$count / $_days',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0, 1),
              minHeight: 6,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
        ],
      ),
    );
  }

  int _streak(List<DailyStat> daily) {
    int s = 0;
    for (final d in daily.reversed) {
      if (d.pct >= 0.6) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }
}

class _StatsBundle {
  final List<DailyStat> daily;
  final Map<int, int> perBlock;
  _StatsBundle({required this.daily, required this.perBlock});
}

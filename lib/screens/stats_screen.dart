import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database.dart';
import '../models/block.dart';
import '../providers/tracker_provider.dart';

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
    final blocks = context.watch<TrackerProvider>().blocks;
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
          padding: const EdgeInsets.all(16),
          children: [
            _rangeChips(),
            const SizedBox(height: 16),
            _summaryRow(avg, streak, b.daily),
            const SizedBox(height: 24),
            Text('Daily completion %',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: _barChart(b.daily)),
            const SizedBox(height: 28),
            Text('Per-block completion (last $_days days)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._perBlockList(blocks, b.perBlock),
          ],
        );
      },
    );
  }

  Widget _rangeChips() {
    return Wrap(
      spacing: 8,
      children: [7, 14, 30].map((d) {
        return ChoiceChip(
          label: Text('$d d'),
          selected: _days == d,
          onSelected: (_) => _setRange(d),
        );
      }).toList(),
    );
  }

  Widget _summaryRow(double avg, int streak, List<DailyStat> daily) {
    final bestDay = daily.isEmpty
        ? null
        : daily.reduce((a, b) => a.pct >= b.pct ? a : b);
    return Row(
      children: [
        Expanded(child: _statTile('Avg', '${(avg * 100).round()}%')),
        const SizedBox(width: 8),
        Expanded(child: _statTile('Streak', '$streak d')),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile(
            'Best',
            bestDay == null
                ? '—'
                : '${(bestDay.pct * 100).round()}%',
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _barChart(List<DailyStat> daily) {
    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        barTouchData: BarTouchData(enabled: true),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
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
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }

  List<Widget> _perBlockList(List<Block> blocks, Map<int, int> counts) {
    final items = [...blocks]..sort((a, b) =>
        (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    return items.map((b) {
      final c = counts[b.id] ?? 0;
      final pct = _days == 0 ? 0.0 : c / _days;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: b.priority.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(b.title)),
              Text('$c / $_days',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1),
                minHeight: 6,
                valueColor:
                    AlwaysStoppedAnimation(b.priority.color),
              ),
            ),
          ],
        ),
      );
    }).toList();
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

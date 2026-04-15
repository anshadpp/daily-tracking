import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database.dart';
import '../providers/tracker_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<List<DailyStat>>? _future;

  @override
  void initState() {
    super.initState();
    _future = AppDatabase.instance.getDailyStats(30);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DailyStat>>(
      future: _future,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snap.data!.reversed.toList();
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: stats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final s = stats[i];
            final pct = (s.pct * 100).round();
            final color = s.pct >= 0.8
                ? Colors.green
                : s.pct >= 0.5
                    ? Colors.orange
                    : Colors.red;
            return InkWell(
              onTap: () {
                context.read<TrackerProvider>().setSelectedDate(s.date);
                DefaultTabController.of(context).animateTo(0);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: s.pct,
                            strokeWidth: 4,
                            backgroundColor:
                                Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                          Text('$pct',
                              style:
                                  const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE, d MMM yyyy').format(s.date),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text('${s.completed} / ${s.total} blocks',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

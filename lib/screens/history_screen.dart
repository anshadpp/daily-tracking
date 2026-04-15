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

  Future<void> _reload() async {
    setState(() {
      _future = AppDatabase.instance.getDailyStats(30);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<DailyStat>>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snap.data!.reversed.toList();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: stats.length,
            itemBuilder: (_, i) {
              final s = stats[i];
              final pct = (s.pct * 100).round();
              final color = s.pct >= 0.8
                  ? const Color(0xFF2E7D32)
                  : s.pct >= 0.5
                      ? const Color(0xFFEF6C00)
                      : s.pct > 0
                          ? const Color(0xFFC62828)
                          : cs.outline;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Material(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      context.read<TrackerProvider>().setSelectedDate(s.date);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                              'Switched to ${DateFormat('d MMM').format(s.date)} — see Today tab'),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: s.pct,
                                  strokeWidth: 4,
                                  backgroundColor:
                                      cs.surfaceContainerHighest,
                                  valueColor:
                                      AlwaysStoppedAnimation(color),
                                ),
                                Text('$pct',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, d MMM yyyy')
                                      .format(s.date),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text('${s.completed} / ${s.total} blocks',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

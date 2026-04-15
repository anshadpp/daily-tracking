import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tracker_provider.dart';
import 'edit_blocks_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Tracker'),
          actions: [
            IconButton(
              tooltip: 'Reschedule reminders',
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: () async {
                await context
                    .read<TrackerProvider>()
                    .rescheduleNotifications();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminders rescheduled')),
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Edit blocks',
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Edit blocks')),
                    body: const EditBlocksScreen(),
                  ),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.checklist), text: 'Today'),
              Tab(icon: Icon(Icons.history), text: 'History'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TodayScreen(),
            HistoryScreen(),
            StatsScreen(),
          ],
        ),
      ),
    );
  }
}

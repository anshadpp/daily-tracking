import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tracker_provider.dart';
import 'edit_blocks_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Today', 'History', 'Stats'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
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
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Reminders rescheduled'),
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Edit blocks',
            icon: const Icon(Icons.tune_rounded),
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
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          HistoryScreen(),
          StatsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.checklist_rounded),
            selectedIcon: Icon(Icons.checklist_rounded, color: cs.primary),
            label: 'Today',
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded, color: cs.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_rounded),
            selectedIcon: Icon(Icons.insights_rounded, color: cs.primary),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}

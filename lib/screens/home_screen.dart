import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tracker_provider.dart';
import '../services/widget_service.dart';
import '../widgets/glass.dart';
import '../services/settings_service.dart';
import 'categories_screen.dart';
import 'edit_blocks_screen.dart';
import 'expenses_screen.dart';
import 'history_screen.dart';
import 'holidays_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  static const _titles = ['Today', 'Expenses', 'History', 'Stats'];

  StreamSubscription<Uri?>? _widgetSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await WidgetService.instance.launchedFrom();
      if (initial != null) _handleUri(initial);
      // Show onboarding then location picker on first launch
      if (mounted && !AppSettings.I.onboardingDone) {
        await _showOnboarding();
      }
      if (mounted && !AppSettings.I.locationPicked) {
        await _showLocationPicker();
      }
    });
    _widgetSub = WidgetService.instance.onLaunch.listen((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  Future<void> _showOnboarding() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _OnboardingDialog(),
    );
    AppSettings.I.onboardingDone = true;
    await AppSettings.I.save();
  }

  Future<void> _showLocationPicker() async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LocationPickerSheet(
        onSelected: (city) async {
          AppSettings.I.city = city.name;
          AppSettings.I.latitude = city.lat;
          AppSettings.I.longitude = city.lng;
          AppSettings.I.locationPicked = true;
          await AppSettings.I.save();
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
    // Reload after picker closes
    if (mounted) {
      await context.read<TrackerProvider>().load();
      await context.read<TrackerProvider>().rescheduleNotifications();
    }
  }

  @override
  void dispose() {
    _widgetSub?.cancel();
    super.dispose();
  }

  void _handleUri(Uri uri) {
    if (!mounted) return;
    // Any launch from widget (open, refresh) → just reload latest state
    context.read<TrackerProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      body: GlassBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      _titles[_index],
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const Spacer(),
                    _GlassAction(
                      icon: Icons.event_busy_outlined,
                      tooltip: 'Holidays',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HolidaysScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassAction(
                      icon: Icons.settings_outlined,
                      tooltip: 'Settings',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassAction(
                      icon: Icons.palette_outlined,
                      tooltip: 'Categories',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CategoriesScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassAction(
                      icon: Icons.notifications_active_outlined,
                      tooltip: 'Reschedule reminders',
                      onTap: () async {
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
                    const SizedBox(width: 8),
                    _GlassAction(
                      icon: Icons.tune_rounded,
                      tooltip: 'Edit blocks',
                      onTap: () => Navigator.push(
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
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  TodayScreen(),
                  ExpensesScreen(),
                  HistoryScreen(),
                  StatsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Glass(
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.checklist_rounded,
                  label: 'Today',
                  selected: _index == 0,
                  color: cs.primary,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Expenses',
                  selected: _index == 1,
                  color: cs.primary,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  selected: _index == 2,
                  color: cs.primary,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.insights_rounded,
                  label: 'Stats',
                  selected: _index == 3,
                  color: cs.primary,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _GlassAction(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Glass(
          borderRadius: BorderRadius.circular(999),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
            horizontal: selected ? 18 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 22),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog();
  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  int _page = 0;

  static const _pages = [
    _OBPage(
      icon: Icons.checklist_rounded,
      title: 'Schedule Blocks',
      body:
          'Create time blocks for your day — work, study, meals, rest. '
          'Tap the tune icon to add blocks. Set which days each block repeats.',
    ),
    _OBPage(
      icon: Icons.mosque_rounded,
      title: 'Prayer Tracking',
      body:
          '5 daily prayers auto-calculated for your location. '
          'Each has a deadline — if missed it becomes Qada. '
          'Track and make up missed prayers from the calendar.',
    ),
    _OBPage(
      icon: Icons.task_alt_rounded,
      title: 'Todos',
      body:
          'Free-form tasks not tied to a time. Add from the Today screen. '
          'Persists until completed. Also visible in your home widget.',
    ),
    _OBPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Expenses',
      body:
          'Log daily spending with categories. See daily totals, '
          'monthly summaries, and a 7-day chart.',
    ),
    _OBPage(
      icon: Icons.widgets_rounded,
      title: 'Home Widget',
      body:
          'Add the widget to your home screen. Mark prayers, todos, '
          'and blocks done directly from the widget — no need to open the app.',
    ),
    _OBPage(
      icon: Icons.backup_rounded,
      title: 'Backup & Restore',
      body:
          'Export your data as JSON or raw database from Settings. '
          'Import on a new phone without losing any history.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = _pages[_page];
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(p.icon, size: 48, color: cs.primary),
          const SizedBox(height: 14),
          Text(p.title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(p.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 18),
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              return Container(
                width: i == _page ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == _page
                      ? cs.primary
                      : cs.outline.withOpacity(0.3),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        if (_page > 0)
          TextButton(
            onPressed: () => setState(() => _page--),
            child: const Text('Back'),
          ),
        FilledButton(
          onPressed: () {
            if (_page < _pages.length - 1) {
              setState(() => _page++);
            } else {
              Navigator.pop(context);
            }
          },
          child: Text(
              _page < _pages.length - 1 ? 'Next' : 'Get Started'),
        ),
      ],
    );
  }
}

class _OBPage {
  final IconData icon;
  final String title;
  final String body;
  const _OBPage(
      {required this.icon, required this.title, required this.body});
}

class _LocationPickerSheet extends StatelessWidget {
  final void Function(CommonCity) onSelected;
  const _LocationPickerSheet({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Glass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Icon(Icons.mosque_rounded, color: cs.primary, size: 32),
            const SizedBox(height: 8),
            Text('Select your location',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    )),
            const SizedBox(height: 4),
            Text(
              'This sets accurate prayer times for your area. You can change it later in Settings.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CommonCity.all.map((c) {
                    return ActionChip(
                      label: Text(c.name),
                      avatar: const Icon(Icons.location_on_outlined, size: 16),
                      onPressed: () => onSelected(c),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

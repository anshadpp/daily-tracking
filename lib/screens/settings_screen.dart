import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/prayer.dart';
import '../providers/tracker_provider.dart';
import '../services/backup_service.dart';
import '../services/prayer_service.dart';
import '../services/settings_service.dart';
import '../widgets/glass.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final s = AppSettings.I;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _cityCtrl;

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController(text: s.latitude.toStringAsFixed(4));
    _lngCtrl = TextEditingController(text: s.longitude.toStringAsFixed(4));
    _cityCtrl = TextEditingController(text: s.city);
  }

  Future<void> _save() async {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat == null || lng == null) return;
    s.latitude = lat;
    s.longitude = lng;
    s.city = _cityCtrl.text.trim();
    await s.save();
    if (mounted) {
      await context.read<TrackerProvider>().load();
      await context.read<TrackerProvider>().rescheduleNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Saved')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sample = PrayerService.instance.forDate(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: GlassBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Glass(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.mosque_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    const Text('Prayer times',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    'Shown on Today based on your location & method.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Enable prayer tracking'),
                    value: s.prayerEnabled,
                    onChanged: (v) async {
                      setState(() => s.prayerEnabled = v);
                      await s.save();
                      if (mounted) {
                        await context.read<TrackerProvider>().load();
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Prayer reminders'),
                    subtitle: const Text(
                        'Notification at each prayer time'),
                    value: s.prayerReminders,
                    onChanged: (v) async {
                      setState(() => s.prayerReminders = v);
                      await s.save();
                      if (mounted) {
                        await context
                            .read<TrackerProvider>()
                            .rescheduleNotifications();
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Location',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CommonCity.all.map((c) {
                      final selected = c.name == s.city;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            s.city = c.name;
                            s.latitude = c.lat;
                            s.longitude = c.lng;
                            _latCtrl.text = c.lat.toStringAsFixed(4);
                            _lngCtrl.text = c.lng.toStringAsFixed(4);
                            _cityCtrl.text = c.name;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2)
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
                            c.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City label (shown on Today)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          decoration:
                              const InputDecoration(labelText: 'Latitude'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          decoration:
                              const InputDecoration(labelText: 'Longitude'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calculation method',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: s.method,
                    isExpanded: true,
                    items: PrayerService.methodChoices
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            ))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => s.method = v);
                      await s.save();
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Asr juristic',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'standard',
                          groupValue: s.asrJuristic,
                          title: const Text('Standard'),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => s.asrJuristic = v);
                            await s.save();
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'hanafi',
                          groupValue: s.asrJuristic,
                          title: const Text('Hanafi'),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => s.asrJuristic = v);
                            await s.save();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save location'),
              ),
            ),
            const SizedBox(height: 20),
            Glass(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today — preview',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  for (final p in sample)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(p.name.icon, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(p.name.label)),
                          Text(
                            DateFormat('HH:mm').format(p.time),
                            style: const TextStyle(
                                fontFeatures: [
                                  FontFeature.tabularFigures()
                                ],
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Glass(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.backup_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    const Text('Backup & Restore',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    'Export your data to transfer to another device, or restore a previous backup.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('EXPORT'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _BackupButton(
                          icon: Icons.data_object_rounded,
                          label: 'JSON',
                          sublabel: 'Human-readable, all tables',
                          onTap: () => _export(context, 'json'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BackupButton(
                          icon: Icons.storage_rounded,
                          label: 'Database',
                          sublabel: 'Raw .db file, fastest',
                          onTap: () => _export(context, 'db'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('IMPORT'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _BackupButton(
                          icon: Icons.upload_file_rounded,
                          label: 'From JSON',
                          sublabel: 'Pick .json backup',
                          onTap: () => _importJson(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BackupButton(
                          icon: Icons.file_open_rounded,
                          label: 'From .db',
                          sublabel: 'Pick database file',
                          onTap: () => _importDb(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Glass(
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.all(16),
              tint: Colors.red.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.warning_rounded, color: Colors.red.shade400),
                    const SizedBox(width: 10),
                    const Text('Danger zone',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.red)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _resetAll(context),
                      icon: const Icon(Icons.delete_forever_rounded,
                          color: Colors.red),
                      label: const Text('Reset all data',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset everything?'),
        content: const Text(
            'This permanently deletes ALL your data:\n'
            '• Schedule blocks & categories\n'
            '• Completions & history\n'
            '• Expenses, todos, holidays\n'
            '• Prayer completions & Qada\n\n'
            'This cannot be undone. Export a backup first.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Resetting...'),
          ],
        ),
      ),
    );
    await context.read<TrackerProvider>().resetAllData();
    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('All data has been reset.'),
      ),
    );
  }

  Future<void> _export(BuildContext context, String type) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Preparing export...')),
    );
    final path = type == 'json'
        ? await BackupService.instance.exportJson()
        : await BackupService.instance.exportDb();
    if (!context.mounted) return;
    scaffold.hideCurrentSnackBar();
    if (path != null) {
      scaffold.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Exported to $path'),
        ),
      );
    } else {
      scaffold.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Export failed'),
        ),
      );
    }
  }

  Future<void> _importJson(BuildContext context) async {
    final confirmed = await _confirmImport(context);
    if (confirmed != true) return;
    if (!context.mounted) return;
    final (ok, count) = await BackupService.instance.importJson();
    if (!context.mounted) return;
    if (ok) {
      await context.read<TrackerProvider>().load();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Imported $count records. Data restored.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Import failed. Check the file format.'),
        ),
      );
    }
  }

  Future<void> _importDb(BuildContext context) async {
    final confirmed = await _confirmImport(context);
    if (confirmed != true) return;
    if (!context.mounted) return;
    final (ok, msg) = await BackupService.instance.importDb();
    if (!context.mounted) return;
    if (ok) {
      await context.read<TrackerProvider>().load();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(msg.isEmpty ? 'Database restored.' : msg),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(msg.isEmpty ? 'Import failed.' : msg),
        ),
      );
    }
  }

  Future<bool?> _confirmImport(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
            'Importing will erase your current data and replace it with '
            'the backup. This cannot be undone.\n\n'
            'Export your current data first if you want to keep it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

class _BackupButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  const _BackupButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 2),
            Text(sublabel,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

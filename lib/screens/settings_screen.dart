import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/prayer.dart';
import '../providers/tracker_provider.dart';
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
          ],
        ),
      ),
    );
  }
}

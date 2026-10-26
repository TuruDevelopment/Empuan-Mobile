import 'package:flutter/material.dart';

import '../../data/contacts_repository.dart';
import '../../data/offline.dart';
import '../../ui/em_ui.dart';
import 'offline_sync.dart';

/// What's saved on this phone for offline use, the switches that control
/// it, and a way to clear it.
class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _Usage {
  const _Usage({required this.sizes, required this.counts, required this.images, required this.contacts});

  final Map<OfflineSection, int> sizes;
  final Map<OfflineSection, int> counts;
  final int images;
  final int contacts;

  int get total => sizes.values.fold(0, (a, b) => a + b) + images + contacts;
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen> {
  _Usage? _usage;
  bool _autoSave = true;
  bool _wifiOnly = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object>([
      OfflineCache.instance.sizes(),
      OfflineCache.instance.counts(),
      OfflineImages.size(),
      ContactsVault.size(),
      OfflinePrefs.autoSaveCourses(),
      OfflinePrefs.wifiOnly(),
    ]);
    if (!mounted) return;
    setState(() {
      _usage = _Usage(
        sizes: results[0] as Map<OfflineSection, int>,
        counts: results[1] as Map<OfflineSection, int>,
        images: results[2] as int,
        contacts: results[3] as int,
      );
      _autoSave = results[4] as bool;
      _wifiOnly = results[5] as bool;
    });
  }

  Future<void> _setAutoSave(bool value) async {
    setState(() => _autoSave = value);
    await OfflinePrefs.setAutoSaveCourses(value);
    if (value) await _saveNow(quiet: true);
  }

  Future<void> _setWifiOnly(bool value) async {
    setState(() => _wifiOnly = value);
    await OfflinePrefs.setWifiOnly(value);
  }

  Future<void> _saveNow({bool quiet = false}) async {
    if (OfflineStatus.instance.offline) {
      if (!quiet) showEmToast(context, 'You’re offline. Saving starts when you’re back online.', icon: Icons.wifi_off_rounded);
      return;
    }
    setState(() => _saving = true);
    await OfflineSync.instance.run(force: true);
    if (!mounted) return;
    setState(() => _saving = false);
    await _load();
    if (mounted && !quiet) showEmToast(context, 'Your courses are saved for offline.', icon: Icons.download_done_rounded);
  }

  Future<void> _clear() async {
    final ok = await showEmConfirm(
      context,
      title: 'Clear saved content?',
      message: 'Courses, articles and pictures saved on this phone will be removed. They’ll download again when you open them online.',
      confirmLabel: 'Clear',
      danger: true,
    );
    if (!ok) return;
    await clearOfflineData(keepContacts: true);
    await _load();
    if (mounted) showEmToast(context, 'Saved content cleared.', icon: Icons.delete_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final usage = _usage;
    return Scaffold(
      appBar: const EmTopBar(title: 'Saved for offline'),
      body: usage == null
          ? const EmLoading()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _UsageCard(usage: usage),
                const SizedBox(height: 20),
                EmGroup(children: [
                  EmRow(
                    title: 'Save my courses automatically',
                    subtitle: 'Lessons from courses you’ve started are kept on this phone',
                    trailing: Switch(value: _autoSave, onChanged: _setAutoSave),
                    onTap: () => _setAutoSave(!_autoSave),
                  ),
                  EmRow(
                    title: 'Download on Wi-Fi only',
                    subtitle: 'Save your mobile data',
                    trailing: Switch(value: _wifiOnly, onChanged: _setWifiOnly),
                    onTap: () => _setWifiOnly(!_wifiOnly),
                  ),
                ]),
                const SizedBox(height: 16),
                const EmNote(
                  icon: Icons.lock_outline_rounded,
                  child: Text('Saved content stays inside Empuan on this phone. It’s erased when you sign out or delete your account.'),
                ),
                const SizedBox(height: 20),
                EmButton(
                  label: 'Save my courses now',
                  icon: Icons.download_rounded,
                  variant: EmButtonVariant.tonal,
                  loading: _saving,
                  onPressed: _autoSave ? _saveNow : null,
                ),
                const SizedBox(height: 12),
                EmButton(label: 'Clear saved content', variant: EmButtonVariant.secondary, onPressed: usage.total > usage.contacts ? _clear : null),
                const SizedBox(height: 10),
                Text(
                  'Your trusted contacts stay saved so SOS keeps working offline.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage});

  final _Usage usage;

  @override
  Widget build(BuildContext context) {
    final courses = usage.counts[OfflineSection.courses] ?? 0;
    final articles = usage.counts[OfflineSection.articles] ?? 0;
    final rows = [
      (AppColors.primary, courses == 0 ? 'Courses' : 'Courses ($courses ${courses == 1 ? 'page' : 'pages'})', usage.sizes[OfflineSection.courses] ?? 0),
      (AppColors.secondary, articles == 0 ? 'Articles' : 'Articles ($articles ${articles == 1 ? 'page' : 'pages'})', usage.sizes[OfflineSection.articles] ?? 0),
      (AppColors.highlight, 'Pictures', usage.images),
      (AppColors.accent, 'Feed, places and profile', usage.sizes[OfflineSection.other] ?? 0),
      (AppColors.blush, 'Trusted contacts, encrypted', usage.contacts),
    ];
    final total = usage.total;
    return EmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('On this phone', style: Theme.of(context).textTheme.titleSmall)),
              Text(formatBytes(total), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: total == 0
                  ? const ColoredBox(color: AppColors.blush)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (color, _, bytes) in rows)
                          if (bytes > 0) Expanded(flex: (bytes * 1000 ~/ total).clamp(1, 1000), child: ColoredBox(color: color)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          for (final (color, label, bytes) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      border: color == AppColors.blush ? Border.all(color: AppColors.line2) : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
                  Text(
                    formatBytes(bytes),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

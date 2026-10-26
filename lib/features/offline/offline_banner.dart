import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/offline.dart';
import '../../ui/em_ui.dart';

/// Rebuilds when the app goes offline or comes back.
class OfflineBuilder extends StatelessWidget {
  const OfflineBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool offline) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OfflineStatus.instance,
      builder: (context, _) => builder(context, OfflineStatus.instance.offline),
    );
  }
}

/// "You're offline. Showing what was saved today at 14:05."
String offlineMessage(DateTime? savedAt, {DateTime? now}) {
  if (savedAt == null) return 'You’re offline. Saved content and SOS still work.';
  final today = now ?? DateTime.now();
  final local = savedAt.toLocal();
  final time = DateFormat('HH:mm').format(local);
  final sameDay = local.year == today.year && local.month == today.month && local.day == today.day;
  final yesterday = today.subtract(const Duration(days: 1));
  final wasYesterday = local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day;
  final when = sameDay ? 'today at $time' : (wasYesterday ? 'yesterday at $time' : 'on ${DateFormat('d MMM').format(local)}');
  return 'You’re offline. Showing what was saved $when.';
}

/// Dark strip at the top of the tabs while the app is offline, under the
/// status bar like the SOS strip.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final reduced = EmMotion.reduced(context);
    return ListenableBuilder(
      listenable: OfflineStatus.instance,
      builder: (context, _) {
        final status = OfflineStatus.instance;
        final strip = !status.offline
            ? const SizedBox(width: double.infinity)
            : Material(
                color: AppColors.textPrimary,
                child: SafeArea(
                  bottom: false,
                  child: Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              offlineMessage(status.savedAt),
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
        // AnimatedSize can't run with a zero duration, so skip it entirely.
        if (reduced) return strip;
        return AnimatedSize(duration: EmMotion.medium, curve: EmMotion.enter, alignment: Alignment.topCenter, child: strip);
      },
    );
  }
}

/// Takes the place of a comment or reply box while offline.
class OfflineInputNote extends StatelessWidget {
  const OfflineInputNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.primaryVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(message, style: const TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.primaryVariant)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

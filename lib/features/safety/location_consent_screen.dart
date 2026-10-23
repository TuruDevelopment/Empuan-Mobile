import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';
import 'sos_controller.dart';

/// Prominent disclosure shown before the system location prompt, as Google
/// Play requires for location access.
class LocationConsentScreen extends StatefulWidget {
  const LocationConsentScreen({super.key, required this.afterSetup, this.onDone});

  /// True when shown at the end of sign-up; false when SOS opened it.
  final bool afterSetup;

  /// Called instead of popping when the screen ends the sign-up flow.
  final VoidCallback? onDone;

  @override
  State<LocationConsentScreen> createState() => _LocationConsentScreenState();
}

class _LocationConsentScreenState extends State<LocationConsentScreen> {
  bool _asking = false;

  Future<void> _finish({required bool allow}) async {
    await SosController.markDisclosureSeen();
    if (allow) {
      setState(() => _asking = true);
      await SosController.requestLocationPermission();
    }
    if (!mounted) return;
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget point(int index, String label) => EmFadeSlideIn(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: text.bodyMedium)),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: const EmTopBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const EmFadeSlideIn(child: Align(alignment: Alignment.centerLeft, child: EmIconTile(Icons.location_on_outlined, size: 56))),
          const SizedBox(height: 20),
          EmFadeSlideIn(index: 1, child: Text('Let SOS include your location', style: text.headlineMedium)),
          const SizedBox(height: 8),
          EmFadeSlideIn(
            index: 2,
            child: Text(
              'Empuan reads your location only at the moment you hold SOS, and adds it to the text for your trusted contacts.',
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          point(3, 'Used only when you send SOS, while the app is open'),
          point(4, 'Never tracked in the background'),
          point(5, 'Not stored on our servers or shared with anyone else'),
          const SizedBox(height: 8),
          EmFadeSlideIn(
            index: 6,
            child: Text(
              'Next, your phone will ask for permission. Choose “While using the app”. You can change this in your phone settings any time.',
              style: text.bodySmall,
            ),
          ),
        ],
      ),
      bottomNavigationBar: EmBottomBar(
        bordered: false,
        child: EmFadeSlideIn(
          index: 7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmButton(label: 'Continue', loading: _asking, onPressed: () => _finish(allow: true)),
              const SizedBox(height: 8),
              EmButton(label: 'Not now', variant: EmButtonVariant.text, onPressed: () => _finish(allow: false)),
            ],
          ),
        ),
      ),
    );
  }
}

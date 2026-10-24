import 'package:flutter/material.dart';

import '../../data/app_version_repository.dart';
import '../../ui/em_ui.dart';
import '../safety/sos_controller.dart';
import 'update_gate.dart';

/// Shown instead of the app when the server no longer supports this build.
/// There is no way back into the app, only forward to the store, plus a way
/// to call 112 that works without updating.
class UpdateRequiredScreen extends StatefulWidget {
  const UpdateRequiredScreen({
    super.key,
    required this.status,
    this.openUpdate = openAppUpdate,
    this.dial = SosController.dial,
  });

  final AppVersionStatus status;
  final Future<bool> Function(String? storeUrl) openUpdate;
  final Future<bool> Function(String number) dial;

  static const fallbackTitle = 'Update Empuan to continue';
  static const fallbackMessage = 'This version of Empuan is no longer supported. Update to the latest version to keep using the app.';

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  bool _opening = false;

  Future<void> _update() async {
    setState(() => _opening = true);
    final opened = await widget.openUpdate(widget.status.storeUrl);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!opened) showEmToast(context, 'Couldn’t open the store. Search for Empuan there to update.');
  }

  Future<void> _call112() async {
    if (!await widget.dial('112') && mounted) {
      showEmToast(context, 'Couldn’t open your phone app. Dial 112 directly.', icon: Icons.phone_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: (constraints.maxHeight - 40).clamp(0, double.infinity)),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(alignment: Alignment.centerLeft, child: EmWordmark(size: 34)),
                      const Spacer(),
                      const SizedBox(height: 24),
                      EmFadeSlideIn(
                        child: Container(
                          height: 168,
                          decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(28)),
                          alignment: Alignment.center,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                            child: const Icon(Icons.system_update_rounded, size: 40, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      EmFadeSlideIn(
                        index: 1,
                        child: Semantics(
                          header: true,
                          child: Text(widget.status.title ?? UpdateRequiredScreen.fallbackTitle, style: text.headlineLarge),
                        ),
                      ),
                      const SizedBox(height: 10),
                      EmFadeSlideIn(
                        index: 2,
                        child: Text(
                          widget.status.message ?? UpdateRequiredScreen.fallbackMessage,
                          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      EmButton(label: 'Update now', icon: Icons.download_rounded, loading: _opening, onPressed: _update),
                      const SizedBox(height: 12),
                      _EmergencyButton(onPressed: _call112),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hint: 'Opens your phone app with 112 filled in. Works without updating.',
      child: EmPressable(
        child: SizedBox(
          height: 52,
          child: TextButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.phone_rounded, size: 20),
            label: const Text('Emergency? Call 112'),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.dangerTint,
              foregroundColor: AppColors.danger,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

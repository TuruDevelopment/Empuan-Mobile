import 'package:flutter/material.dart';

import '../ui/em_ui.dart';

/// Round send button for message and reply bars. It grows into place when
/// there is something to send and turns into a spinner while sending.
class SendButton extends StatelessWidget {
  const SendButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.sending,
    required this.onPressed,
    this.size = 44,
  });

  final String label;
  final bool enabled;
  final bool sending;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final duration = EmMotion.reduced(context) ? Duration.zero : EmMotion.medium;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: EmMotion.enter,
        switchOutCurve: EmMotion.exit,
        child: sending
            ? Semantics(
                key: const ValueKey('sending'),
                label: 'Sending',
                child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))),
              )
            : AnimatedScale(
                key: const ValueKey('send'),
                scale: enabled ? 1 : 0.86,
                duration: duration,
                curve: enabled ? Curves.easeOutBack : EmMotion.exit,
                child: AnimatedOpacity(
                  opacity: enabled ? 1 : 0.45,
                  duration: duration,
                  child: EmIconButton(
                    icon: Icons.send_rounded,
                    label: label,
                    size: size,
                    style: EmIconButtonStyle.primary,
                    onPressed: enabled ? onPressed : null,
                  ),
                ),
              ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/contacts_repository.dart';
import '../../ui/em_ui.dart';
import 'contact_sheet.dart';
import 'location_consent_screen.dart';
import 'sos_controller.dart';

/// Entry point after the SOS button has been held for 3 seconds.
Future<void> startSosFlow(BuildContext context) async {
  final controller = SosController.instance;
  List<Contact> contacts;
  try {
    contacts = await controller.trustedContacts();
  } catch (_) {
    contacts = const [];
  }
  if (!context.mounted) return;

  if (contacts.isEmpty) {
    await showNoContactsSheet(context);
    return;
  }

  if (!await SosController.hasLocationPermission() && !await SosController.disclosureSeen()) {
    if (!context.mounted) return;
    await pushScreen<void>(context, const LocationConsentScreen(afterSetup: false));
  }
  if (!context.mounted) return;
  await pushScreen<void>(context, SosCountdownScreen(contacts: contacts));
}

Future<void> showNoContactsSheet(BuildContext context) {
  return showEmSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EmSheetHeader(
          icon: Icons.person_off_outlined,
          iconTone: EmTileTone.danger,
          title: 'No one to alert yet',
          message: 'SOS texts your trusted contacts. Add someone now. It takes a few seconds.',
        ),
        const SizedBox(height: 20),
        EmButton(
          label: 'Add a trusted contact',
          onPressed: () async {
            Navigator.of(ctx).pop();
            await showContactSheet(context, kind: ContactKind.trusted);
          },
        ),
        const SizedBox(height: 8),
        EmButton(
          label: 'Call 112 now',
          icon: Icons.call_rounded,
          variant: EmButtonVariant.danger,
          onPressed: () => SosController.dial('112'),
        ),
      ],
    ),
  );
}

/// Full-screen countdown. Cancel is the large, easy target.
class SosCountdownScreen extends StatefulWidget {
  const SosCountdownScreen({super.key, required this.contacts, this.seconds = 3});

  final List<Contact> contacts;
  final int seconds;

  @override
  State<SosCountdownScreen> createState() => _SosCountdownScreenState();
}

class _SosCountdownScreenState extends State<SosCountdownScreen> {
  late int _left = widget.seconds;
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) {
        t.cancel();
        _send();
      } else {
        setState(() => _left--);
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    _timer?.cancel();
    setState(() => _sending = true);
    final position = await SosController.instance.currentPosition();
    final message = SosController.helpMessage(position);
    final opened = await SosController.openMessages(widget.contacts, message);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SosHandoffScreen(contacts: widget.contacts, message: message, opened: opened, hasLocation: position != null),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final names = namesList(widget.contacts);
    return Scaffold(
      backgroundColor: AppColors.danger,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              const Spacer(),
              const Text('SOS', style: TextStyle(color: AppColors.dangerTint, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_left),
                        tween: Tween(begin: _left / widget.seconds, end: (_left - 1) / widget.seconds),
                        duration: const Duration(seconds: 1),
                        builder: (_, v, __) => CircularProgressIndicator(
                          value: _sending ? null : v,
                          strokeWidth: 12,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                    Semantics(
                      liveRegion: true,
                      label: _sending ? 'Opening messages' : 'Sending in $_left seconds',
                      child: ExcludeSemantics(
                        child: _sending
                            ? const Icon(Icons.sms_outlined, color: Colors.white, size: 56)
                            : Text('$_left', style: const TextStyle(color: Colors.white, fontSize: 84, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _sending ? 'Getting your location…' : 'Alerting $names',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your messages app will open with a help text and your current location.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.dangerTint, fontSize: 15, height: 1.45),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: TextButton(
                  onPressed: _sending ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _sending ? null : _send,
                style: TextButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52)),
                child: const Text('Send now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the user returns from the messages app. Empuan can't tell
/// whether the text was sent, so it asks.
class SosHandoffScreen extends StatelessWidget {
  const SosHandoffScreen({
    super.key,
    required this.contacts,
    required this.message,
    required this.opened,
    required this.hasLocation,
  });

  final List<Contact> contacts;
  final String message;
  final bool opened;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    final first = contacts.first;
    return Scaffold(
      appBar: const EmTopBar(title: 'SOS', closeIcon: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(opened ? 'Did your message send?' : 'Your messages app didn’t open',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            opened
                ? 'Empuan can’t send texts for you, so check it went through.'
                : 'Call someone instead, or try opening your messages app again.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 20),
          EmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('To: ${namesList(contacts)}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary))),
                    Text(DateFormat.Hm().format(DateTime.now()), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 290),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                  ),
                ),
                if (!hasLocation) ...[
                  const SizedBox(height: 10),
                  Text('Location wasn’t available, so it isn’t in the text.', style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (opened) ...[
            EmButton(
              label: 'Yes, it’s sent',
              onPressed: () {
                SosController.instance.markSent(contacts);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
          ],
          EmButton(
            label: 'Open messages again',
            variant: opened ? EmButtonVariant.secondary : EmButtonVariant.primary,
            onPressed: () => SosController.openMessages(contacts, message),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: EmButton(
                  label: 'Call ${first.name}',
                  icon: Icons.call_rounded,
                  variant: EmButtonVariant.tonal,
                  onPressed: () => SosController.dial(first.phone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EmButton(
                  label: 'Call 112',
                  icon: Icons.call_rounded,
                  variant: EmButtonVariant.danger,
                  onPressed: () => SosController.dial('112'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Red strip shown at the top of the app while an SOS is active.
class SosActiveBanner extends StatelessWidget {
  const SosActiveBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SosController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.active) return const SizedBox.shrink();
        return Material(
          color: AppColors.danger,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SOS sent at ${DateFormat.Hm().format(controller.sentAt!)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('${namesList(controller.alerted)} ${controller.alerted.length == 1 ? 'has' : 'have'} your location',
                            style: const TextStyle(color: AppColors.dangerTint, fontSize: 12)),
                      ],
                    ),
                  ),
                  EmButton(
                    label: 'I’m safe',
                    variant: EmButtonVariant.white,
                    small: true,
                    expand: false,
                    onPressed: () => showImSafeSheet(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showImSafeSheet(BuildContext context) {
  final controller = SosController.instance;
  final contacts = controller.alerted;
  return showEmSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmSheetHeader(
          icon: Icons.verified_user_outlined,
          title: 'Glad you’re safe',
          message: 'Let ${namesList(contacts)} know so they can stop worrying. We’ll open your messages app with the text ready.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(14)),
          child: const Text('“${SosController.safeMessage}”', style: TextStyle(fontSize: 14)),
        ),
        const SizedBox(height: 20),
        EmButton(
          label: 'Send “I’m safe” text',
          onPressed: () async {
            await SosController.openMessages(contacts, SosController.safeMessage);
            controller.end();
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        ),
        const SizedBox(height: 8),
        EmButton(
          label: 'End SOS without texting',
          variant: EmButtonVariant.text,
          onPressed: () {
            controller.end();
            Navigator.of(ctx).pop();
          },
        ),
      ],
    ),
  );
}

/// The raised SOS button in the middle of the tab bar. It only fires after a
/// 3-second press, so a pocket tap can't send an alert.
class SosHoldButton extends StatefulWidget {
  const SosHoldButton({super.key, required this.onTriggered});

  final VoidCallback onTriggered;

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        _hold.reset();
        widget.onTriggered();
      }
    });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.selectionClick();
    _hold.forward(from: 0);
  }

  void _cancel() {
    if (_hold.isAnimating) _hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'SOS',
      hint: 'Press and hold for 3 seconds to alert your trusted contacts',
      onLongPress: widget.onTriggered,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _start(),
        onPointerUp: (_) {
          if (_hold.value < 0.2) {
            showEmToast(context, 'Press and hold SOS for 3 seconds to send an alert.', icon: Icons.touch_app_outlined);
          }
          _cancel();
        },
        onPointerCancel: (_) => _cancel(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -22),
              child: AnimatedBuilder(
                animation: _hold,
                builder: (_, __) => Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 5),
                    boxShadow: const [BoxShadow(color: Color(0x59B8304A), blurRadius: 18, offset: Offset(0, 6))],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_hold.value > 0)
                        SizedBox.expand(
                          child: CircularProgressIndicator(value: _hold.value, strokeWidth: 4, color: Colors.white, backgroundColor: Colors.white24),
                        ),
                      const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

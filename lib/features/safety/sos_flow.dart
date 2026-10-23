import 'dart:async';
import 'dart:math' as math;

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
        const EmFadeSlideIn(
          child: EmSheetHeader(
            icon: Icons.person_off_outlined,
            iconTone: EmTileTone.danger,
            title: 'No one to alert yet',
            message: 'SOS texts your trusted contacts. Add someone now. It takes a few seconds.',
          ),
        ),
        const SizedBox(height: 20),
        EmFadeSlideIn(
          index: 1,
          child: EmButton(
            label: 'Add a trusted contact',
            onPressed: () async {
              Navigator.of(ctx).pop();
              await showContactSheet(context, kind: ContactKind.trusted);
            },
          ),
        ),
        const SizedBox(height: 8),
        EmFadeSlideIn(
          index: 2,
          child: EmButton(
            label: 'Call 112 now',
            icon: Icons.call_rounded,
            variant: EmButtonVariant.danger,
            onPressed: () => SosController.dial('112'),
          ),
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

class _SosCountdownScreenState extends State<SosCountdownScreen> with TickerProviderStateMixin {
  late int _left = widget.seconds;
  Timer? _timer;
  bool _sending = false;

  // One continuous sweep over the whole countdown, so the ring doesn't
  // restart its easing every second.
  late final AnimationController _ring = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds), value: 1);

  // Slow breathing glow behind the ring: it tells the user something is
  // about to happen without competing with the number.
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  bool _motionStarted = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionStarted) return;
    _motionStarted = true;
    if (EmMotion.reduced(context)) {
      _breath.value = 0.5;
    } else {
      _ring.animateTo(0);
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ring.dispose();
    _breath.dispose();
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
    final reduced = EmMotion.reduced(context);
    final swap = reduced ? Duration.zero : EmMotion.medium;
    return Scaffold(
      backgroundColor: AppColors.danger,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              const Spacer(),
              const EmFadeSlideIn(
                child: Text('SOS', style: TextStyle(color: AppColors.dangerTint, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 24),
              EmFadeSlideIn(
                index: 1,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Painted larger than the box without affecting layout.
                      AnimatedBuilder(
                        animation: _breath,
                        builder: (_, __) {
                          final t = Curves.easeInOut.transform(_breath.value);
                          return Transform.scale(
                            scale: 1.04 + 0.14 * t,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06 + 0.08 * t),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox.expand(
                        child: AnimatedSwitcher(
                          duration: swap,
                          // Expand so the ring keeps filling the 200px box.
                          layoutBuilder: (current, previous) => Stack(
                            fit: StackFit.expand,
                            children: [...previous, if (current != null) current],
                          ),
                          child: _sending
                              ? const CircularProgressIndicator(
                                  key: ValueKey('sending'),
                                  strokeWidth: 12,
                                  color: Colors.white,
                                  backgroundColor: Colors.white24,
                                )
                              : AnimatedBuilder(
                                  key: const ValueKey('counting'),
                                  animation: _ring,
                                  builder: (_, __) => CircularProgressIndicator(
                                    // Reduced motion: step once per second instead of sweeping.
                                    value: reduced ? _left / widget.seconds : _ring.value,
                                    strokeWidth: 12,
                                    color: Colors.white,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                        ),
                      ),
                      Semantics(
                        liveRegion: true,
                        label: _sending ? 'Opening messages' : 'Sending in $_left seconds',
                        child: ExcludeSemantics(
                          child: AnimatedSwitcher(
                            duration: swap,
                            switchInCurve: EmMotion.enter,
                            switchOutCurve: EmMotion.exit,
                            transitionBuilder: (child, a) => FadeTransition(
                              opacity: a,
                              child: ScaleTransition(scale: Tween(begin: 0.6, end: 1.0).animate(a), child: child),
                            ),
                            child: _sending
                                ? const Icon(Icons.sms_outlined, key: ValueKey('sms'), color: Colors.white, size: 56)
                                : Text(
                                    '$_left',
                                    key: ValueKey(_left),
                                    style: const TextStyle(color: Colors.white, fontSize: 84, fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              EmFadeSlideIn(
                index: 2,
                child: EmStateSwitcher(
                  stateKey: _sending,
                  child: Text(
                    _sending ? 'Getting your location…' : 'Alerting $names',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const EmFadeSlideIn(
                index: 3,
                child: Text(
                  'Your messages app will open with a help text and your current location.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.dangerTint, fontSize: 15, height: 1.45),
                ),
              ),
              const Spacer(),
              EmFadeSlideIn(
                index: 4,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: EmPressable(
                    enabled: !_sending,
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
                ),
              ),
              const SizedBox(height: 8),
              EmFadeSlideIn(
                index: 5,
                child: TextButton(
                  onPressed: _sending ? null : _send,
                  style: TextButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52)),
                  child: const Text('Send now'),
                ),
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
          EmFadeSlideIn(
            child: Text(opened ? 'Did your message send?' : 'Your messages app didn’t open',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          const SizedBox(height: 8),
          EmFadeSlideIn(
            index: 1,
            child: Text(
              opened
                  ? 'Empuan can’t send texts for you, so check it went through.'
                  : 'Call someone instead, or try opening your messages app again.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          EmFadeSlideIn(
            index: 2,
            child: EmCard(
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
                    child: _SentBubbleIn(
                      delay: EmMotion.staggerFor(2) + EmMotion.medium,
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
                  ),
                  if (!hasLocation) ...[
                    const SizedBox(height: 10),
                    Text('Location wasn’t available, so it isn’t in the text.', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (opened) ...[
            EmFadeSlideIn(
              index: 4,
              child: EmButton(
                label: 'Yes, it’s sent',
                onPressed: () {
                  SosController.instance.markSent(contacts);
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          EmFadeSlideIn(
            index: 5,
            child: EmButton(
              label: 'Open messages again',
              variant: opened ? EmButtonVariant.secondary : EmButtonVariant.primary,
              onPressed: () => SosController.openMessages(contacts, message),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          EmFadeSlideIn(
            index: 6,
            child: Row(
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
          ),
        ],
      ),
    );
  }
}

/// Pops the message bubble in from its tail corner, the way a chat app shows
/// a message you just sent.
class _SentBubbleIn extends StatefulWidget {
  const _SentBubbleIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_SentBubbleIn> createState() => _SentBubbleInState();
}

class _SentBubbleInState extends State<_SentBubbleIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: EmMotion.slow);
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: EmMotion.enter));
  late final Animation<double> _scale = Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0.12, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: EmMotion.enter));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (EmMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, alignment: Alignment.bottomRight, child: widget.child),
      ),
    );
  }
}

/// Red strip shown at the top of the app while an SOS is active.
class SosActiveBanner extends StatefulWidget {
  const SosActiveBanner({super.key});

  @override
  State<SosActiveBanner> createState() => _SosActiveBannerState();
}

class _SosActiveBannerState extends State<SosActiveBanner> with SingleTickerProviderStateMixin {
  final _controller = SosController.instance;
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: EmMotion.slow,
    reverseDuration: EmMotion.medium,
    value: _controller.active ? 1 : 0,
  )..addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !_controller.active && _sentAt != null) {
        setState(() => _sentAt = null);
      }
    });
  late final Animation<double> _size = CurvedAnimation(parent: _show, curve: EmMotion.enter, reverseCurve: EmMotion.exit);

  // Kept after the SOS ends so the strip still has its text while it slides away.
  DateTime? _sentAt;
  List<Contact> _alerted = const [];

  @override
  void initState() {
    super.initState();
    _sentAt = _controller.sentAt;
    _alerted = _controller.alerted;
    _controller.addListener(_sync);
  }

  @override
  void dispose() {
    _controller.removeListener(_sync);
    _show.dispose();
    super.dispose();
  }

  void _sync() {
    final reduced = EmMotion.reduced(context);
    if (_controller.active) {
      setState(() {
        _sentAt = _controller.sentAt;
        _alerted = _controller.alerted;
      });
      if (reduced) {
        _show.value = 1;
      } else {
        _show.forward();
      }
    } else if (reduced) {
      _show.value = 0;
    } else {
      _show.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentAt = _sentAt;
    if (sentAt == null) return const SizedBox.shrink();
    // Bottom-aligned inside a growing clip, so the strip appears to slide down
    // from the status bar while the page below eases out of its way.
    return SizeTransition(
      sizeFactor: _size,
      alignment: Alignment.bottomCenter,
      child: Material(
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
                      Text('SOS sent at ${DateFormat.Hm().format(sentAt)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('${namesList(_alerted)} ${_alerted.length == 1 ? 'has' : 'have'} your location',
                          style: const TextStyle(color: AppColors.dangerTint, fontSize: 12)),
                    ],
                  ),
                ),
                EmButton(
                  label: 'I’m safe',
                  variant: EmButtonVariant.white,
                  small: true,
                  expand: false,
                  onPressed: () {
                    if (_controller.active) showImSafeSheet(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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
  const SosHoldButton({super.key, required this.onTriggered, this.onPractice, this.faceKey});

  final VoidCallback onTriggered;

  /// Set during the app tour's practice step. A completed hold then calls
  /// this instead of [onTriggered]: the ring fills and the phone buzzes, but
  /// no countdown, message or location request ever starts.
  final VoidCallback? onPractice;

  /// Put on the round face so the app tour can measure exactly where it is
  /// drawn.
  final Key? faceKey;

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton> with TickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        if (!EmMotion.reduced(context)) _burst.forward(from: 0);
        _fired = true;
        _hold.reset();
        if (_practiceHold) {
          // If the tour moved on mid-hold this does nothing. A practice hold
          // never falls through to a real alert.
          widget.onPractice?.call();
        } else {
          widget.onTriggered();
        }
      }
    });

  // Plays once when the hold completes: a ring bursts outward and the button pops.
  late final AnimationController _burst = AnimationController(vsync: this, duration: EmMotion.slow);

  bool _down = false;

  // Set when a hold completes, so lifting the finger afterwards doesn't show
  // the "press and hold" hint.
  bool _fired = false;

  // Fixed when the finger goes down, so practice can't become real (or real
  // become practice) if the tour starts or ends during a hold.
  bool _practiceHold = false;

  @override
  void dispose() {
    _hold.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  void _start() {
    HapticFeedback.selectionClick();
    _setDown(true);
    _fired = false;
    _practiceHold = widget.onPractice != null;
    _hold.forward(from: 0);
  }

  void _cancel() {
    _setDown(false);
    if (_hold.isAnimating) _hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = EmMotion.reduced(context);
    // Raised above the tab bar. The translate wraps the touch area too, so
    // the whole face responds, not just its lower half.
    return Transform.translate(
      offset: const Offset(0, -22),
      child: Semantics(
        button: true,
        label: 'SOS',
        hint: 'Press and hold for 3 seconds to alert your trusted contacts',
        onLongPress: widget.onPractice ?? widget.onTriggered,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _start(),
          onPointerUp: (_) {
            if (!_fired && _hold.value < 0.2) {
              showEmToast(context, 'Press and hold SOS for 3 seconds to send an alert.', icon: Icons.touch_app_outlined);
            }
            _cancel();
          },
          onPointerCancel: (_) => _cancel(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _down && !reduced ? 0.94 : 1,
                duration: EmMotion.fast,
                curve: _down ? EmMotion.exit : EmMotion.enter,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_hold, _burst]),
                  builder: (_, __) {
                    // A quick swell and settle; sin keeps it at 1 at both ends.
                    final pop = 1 + 0.12 * math.sin(math.pi * Curves.easeOut.transform(_burst.value));
                    return CustomPaint(
                      painter: _SosHaloPainter(hold: _hold.value, burst: _burst.value, pulse: !reduced),
                      child: Transform.scale(
                        scale: pop,
                        child: Container(
                          key: widget.faceKey,
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Red glow around the SOS button. It only exists while the button is held
/// (the tab bar stays still at rest), grows with the hold and beats once per
/// second in step with the 3-second count.
class _SosHaloPainter extends CustomPainter {
  _SosHaloPainter({required this.hold, required this.burst, required this.pulse});

  final double hold;
  final double burst;
  final bool pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (hold > 0) {
      final beat = pulse ? 0.5 - 0.5 * math.cos(2 * math.pi * hold * 3) : 0.0;
      final fadeIn = (hold * 6).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        radius + 2 + 10 * hold + 4 * beat,
        Paint()..color = AppColors.danger.withValues(alpha: (0.16 + 0.12 * beat) * fadeIn),
      );
    }
    if (burst > 0 && burst < 1) {
      final t = Curves.easeOut.transform(burst);
      canvas.drawCircle(
        center,
        radius + 28 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - t) + 1
          ..color = AppColors.danger.withValues(alpha: 0.5 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_SosHaloPainter old) => old.hold != hold || old.burst != burst || old.pulse != pulse;
}

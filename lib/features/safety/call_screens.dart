import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/em_ui.dart';

// The call screens imitate the phone's own dialer, so they use a neutral dark
// palette instead of the brand colours.
const _callBackground = Color(0xFF1F1B1D);
const _callAvatar = Color(0xFF4A4447);
const _callButton = Color(0xFF3A3437);
const _callMuted = Color(0xFFCFC8CB);
const _declineRed = Color(0xFFE0404F);
const _acceptGreen = Color(0xFF2E9E5B);

/// Fake incoming call. Rings until the user declines or accepts.
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.name,
    this.relation = '',
    this.ringtone = 'ringtone.mp3',
    this.vibrate = true,
  });

  final String name;

  /// Shown under the name, like the number label on a real call.
  final String relation;

  /// Asset path relative to assets/, as used by [AssetSource].
  final String ringtone;
  final bool vibrate;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  Timer? _buzz;
  int _tick = 0;

  // Drives both the ripples around the avatar and the Accept nudge, so the
  // screen reads as one ringing rhythm.
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final Animation<double> _nudge = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0).chain(CurveTween(curve: Curves.easeOut)), weight: 12),
    TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 28),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
  ]).animate(_ring);
  bool _motionStarted = false;

  @override
  void initState() {
    super.initState();
    _startRinging();
    if (widget.vibrate) {
      // Haptic calls are single short pulses, so fire a quick burst every
      // couple of seconds to feel like a ringing phone.
      _buzz = Timer.periodic(const Duration(milliseconds: 120), (_) {
        if (_tick++ % 18 < 5) HapticFeedback.vibrate();
      });
    }
  }

  Future<void> _startRinging() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(widget.ringtone), volume: 1.0);
    } catch (_) {
      // The call screen still works silently if audio fails.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionStarted) return;
    _motionStarted = true;
    if (!EmMotion.reduced(context)) _ring.repeat();
  }

  @override
  void dispose() {
    _ring.dispose();
    _buzz?.cancel();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  void _accept() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: EmMotion.reduced(context) ? Duration.zero : EmMotion.slow,
        pageBuilder: (_, __, ___) => InCallScreen(name: widget.name),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.relation.trim().isEmpty ? 'Mobile' : widget.relation;
    return _CallScaffold(
      child: Column(
        children: [
          const SizedBox(height: 96),
          ExcludeSemantics(
            child: CustomPaint(
              painter: _RipplePainter(_ring, animate: !EmMotion.reduced(context)),
              child: EmFadeSlideIn(
                offset: Offset.zero,
                child: Container(
                  width: 104,
                  height: 104,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: _callAvatar, shape: BoxShape.circle),
                  child: Text(
                    initialsOf(widget.name).characters.first,
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          EmFadeSlideIn(index: 1, child: _CallTitle(widget.name)),
          const SizedBox(height: 8),
          EmFadeSlideIn(index: 2, child: Text(label, style: const TextStyle(color: _callMuted, fontSize: 17))),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundAction(
                  icon: Icons.call_end_rounded,
                  label: 'Decline',
                  color: _declineRed,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _RoundAction(icon: Icons.call_rounded, label: 'Accept', color: _acceptGreen, onTap: _accept, lift: _nudge),
              ],
            ),
          ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}

/// Rings spreading out from the avatar like a ringing phone. Three rings
/// share one loop, a third of a cycle apart.
class _RipplePainter extends CustomPainter {
  _RipplePainter(this.progress, {required this.animate}) : super(repaint: progress);

  final Animation<double> progress;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    // Reduced motion: two still rings keep the look without movement.
    final phases = animate ? [for (var i = 0; i < 3; i++) (progress.value + i / 3) % 1] : const [0.3, 0.65];
    for (final p in phases) {
      final t = Curves.easeOut.transform(p);
      canvas.drawCircle(
        center,
        radius + 60 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.22 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.animate != animate || old.progress != progress;
}

/// Fake ongoing call with a running timer. The controls only toggle visually.
class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key, required this.name});

  final String name;

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  final _watch = Stopwatch()..start();
  late final Timer _timer;
  bool _muted = false;
  bool _keypad = false;
  bool _speaker = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _elapsed {
    final d = _watch.elapsed;
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return _CallScaffold(
      child: Column(
        children: [
          const SizedBox(height: 80),
          _CallTitle(widget.name),
          const SizedBox(height: 8),
          Semantics(
            label: _elapsed,
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // One switcher per character, so only the digits that change roll over.
                for (final ch in _elapsed.characters)
                  EmAnimatedSwap(
                    valueKey: ch,
                    child: Text(ch, style: const TextStyle(color: _callMuted, fontSize: 17, fontFeatures: [FontFeature.tabularFigures()])),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ToggleAction(
                  icon: _muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                  label: 'Mute',
                  on: _muted,
                  onTap: () => setState(() => _muted = !_muted),
                ),
                _ToggleAction(
                  icon: Icons.dialpad_rounded,
                  label: 'Keypad',
                  on: _keypad,
                  onTap: () => setState(() => _keypad = !_keypad),
                ),
                _ToggleAction(
                  icon: Icons.volume_up_rounded,
                  label: 'Speaker',
                  on: _speaker,
                  onTap: () => setState(() => _speaker = !_speaker),
                ),
              ],
            ),
          ),
          const Spacer(),
          _RoundAction(
            icon: Icons.call_end_rounded,
            label: 'End call',
            showLabel: false,
            color: _declineRed,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}

class _CallScaffold extends StatelessWidget {
  const _CallScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _callBackground,
        body: SafeArea(child: SizedBox(width: double.infinity, child: child)),
      ),
    );
  }
}

class _CallTitle extends StatelessWidget {
  const _CallTitle(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 34, height: 40 / 34, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.showLabel = true,
    this.lift,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool showLabel;

  /// Vertical offset for the button, used to nudge Accept.
  final Animation<double>? lift;

  @override
  Widget build(BuildContext context) {
    Widget circle = EmPressable(
      scale: 0.9,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 72, height: 72, child: Icon(icon, color: Colors.white, size: 32)),
        ),
      ),
    );
    final lift = this.lift;
    if (lift != null) {
      circle = AnimatedBuilder(
        animation: lift,
        builder: (_, child) => Transform.translate(offset: Offset(0, lift.value), child: child),
        child: circle,
      );
    }
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          if (showLabel) ...[
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: _callMuted, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

class _ToggleAction extends StatelessWidget {
  const _ToggleAction({required this.icon, required this.label, required this.on, required this.onTap});

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = EmMotion.reduced(context) ? Duration.zero : EmMotion.medium;
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmPressable(
            scale: 0.92,
            child: AnimatedContainer(
              duration: duration,
              curve: EmMotion.enter,
              width: 72,
              height: 72,
              decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Colors.white : _callButton),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: duration,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(scale: Tween(begin: 0.7, end: 1.0).animate(a), child: child),
                      ),
                      child: Icon(icon, key: ValueKey((icon, on)), color: on ? _callBackground : Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: _callMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/em_ui.dart';

/// Loud looping alarm. Starts on open and stops when the screen closes.
class SirenScreen extends StatefulWidget {
  const SirenScreen({super.key});

  @override
  State<SirenScreen> createState() => _SirenScreenState();
}

class _SirenScreenState extends State<SirenScreen> with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _play();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  void _syncPulse() {
    if (_playing && !EmMotion.reduced(context)) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      // Freeze rather than reset, so the rings fade out from where they are.
      _pulse.stop();
    }
  }

  Future<void> _play() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('police_siren.wav'));
      if (!mounted) return;
      setState(() => _playing = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _playing = false);
      showEmToast(context, 'Couldn’t play the siren. Try again.');
    }
    if (mounted) _syncPulse();
  }

  Future<void> _stop() async {
    setState(() => _playing = false);
    _syncPulse();
    try {
      await _player.stop();
    } catch (_) {
      // Already stopped.
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryVariant,
        appBar: const EmTopBar(title: 'Siren', backgroundColor: AppColors.primaryVariant, foregroundColor: Colors.white),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    child: Column(
                      children: [
                        _SirenButton(playing: _playing, pulse: _pulse, onTap: _playing ? _stop : _play),
                        const SizedBox(height: 36),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _playing ? 'Siren is playing' : 'Tap to play the siren',
                            textAlign: TextAlign.center,
                            style: text.headlineMedium?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'It stops when you leave this screen.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(color: AppColors.surfaceAlt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Turn your volume all the way up for the loudest sound',
                        style: TextStyle(color: Colors.white, fontSize: 13, height: 18 / 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SirenButton extends StatelessWidget {
  const _SirenButton({required this.playing, required this.pulse, required this.onTap});

  final bool playing;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduced = EmMotion.reduced(context);
    final swap = reduced ? Duration.zero : EmMotion.medium;
    final button = Semantics(
      button: true,
      label: playing ? 'Stop siren' : 'Play siren',
      onTap: onTap,
      excludeSemantics: true,
      child: EmPressable(
        scale: 0.95,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 148,
              height: 148,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: swap,
                    switchInCurve: EmMotion.enter,
                    switchOutCurve: EmMotion.exit,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: RotationTransition(
                        turns: Tween(begin: -0.125, end: 0.0).animate(a),
                        child: ScaleTransition(scale: a, child: child),
                      ),
                    ),
                    child: Icon(
                      playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      key: ValueKey(playing),
                      color: AppColors.danger,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 6),
                  EmAnimatedSwap(
                    valueKey: playing,
                    child: Text(
                      playing ? 'Stop' : 'Play',
                      style: const TextStyle(color: AppColors.danger, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // [on] eases between the resting and playing looks so starting and
    // stopping never snaps.
    return SizedBox(
      width: 260,
      height: 260,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: playing ? 1 : 0),
        duration: reduced ? Duration.zero : EmMotion.slow,
        curve: EmMotion.enter,
        child: button,
        builder: (context, on, child) => CustomPaint(
          painter: _SirenRingsPainter(pulse, on: on, ripple: !reduced),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Two soft halos behind the button, plus rings that spread outward from it
/// while the siren plays.
class _SirenRingsPainter extends CustomPainter {
  _SirenRingsPainter(this.pulse, {required this.on, required this.ripple}) : super(repaint: pulse);

  final Animation<double> pulse;
  final double on;
  final bool ripple;

  static const _button = 74.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final fill = Paint();
    fill.color = AppColors.error.withValues(alpha: 0.08 + 0.10 * on);
    canvas.drawCircle(center, 118, fill);
    fill.color = AppColors.error.withValues(alpha: 0.14 + 0.18 * on);
    canvas.drawCircle(center, 96, fill);

    if (!ripple || on == 0) return;
    final edge = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      final p = (pulse.value + i / 3) % 1;
      final t = Curves.easeOut.transform(p);
      canvas.drawCircle(
        center,
        _button + (edge - _button) * t,
        Paint()..color = AppColors.error.withValues(alpha: 0.28 * (1 - p) * on),
      );
    }
  }

  @override
  bool shouldRepaint(_SirenRingsPainter old) => old.on != on || old.ripple != ripple || old.pulse != pulse;
}

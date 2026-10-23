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
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_playing && !reduceMotion) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
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
    final button = Semantics(
      button: true,
      label: playing ? 'Stop siren' : 'Play siren',
      onTap: onTap,
      excludeSemantics: true,
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
                Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded, color: AppColors.danger, size: 40),
                const SizedBox(height: 6),
                Text(
                  playing ? 'Stop' : 'Play',
                  style: const TextStyle(color: AppColors.danger, fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final grow = playing ? pulse.value : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              _Ring(size: 236 + 24 * grow, alpha: playing ? 0.18 : 0.08),
              _Ring(size: 192 + 8 * grow, alpha: playing ? 0.32 : 0.14),
              child!,
            ],
          );
        },
        child: button,
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: alpha), shape: BoxShape.circle),
    );
  }
}

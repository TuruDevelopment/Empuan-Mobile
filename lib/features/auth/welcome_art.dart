import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';

/// Illustrations for the welcome carousel: real app moments floating on blush
/// shapes. Drawn in code, so they stay sharp on any screen and move gently;
/// with reduced motion they hold still in their finished state.
class WelcomeArt extends StatefulWidget {
  const WelcomeArt(this.slide, {super.key});

  /// 0 backup, 1 learn, 2 SOS, 3 Empuan AI.
  final int slide;

  @override
  State<WelcomeArt> createState() => _WelcomeArtState();
}

class _WelcomeArtState extends State<WelcomeArt> with SingleTickerProviderStateMixin {
  // One 6 s loop drives everything: cards bob once, bars fill twice, the SOS
  // ring sweeps twice.
  late final _loop = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = EmMotion.reduced(context);
    if (_still) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FittedBox(
        child: SizedBox(
          width: 342,
          height: 330,
          child: AnimatedBuilder(
            animation: _loop,
            builder: (context, _) {
              final art = _Art(_still ? null : _loop.value);
              return DefaultTextStyle.merge(
                style: const TextStyle(color: AppColors.textPrimary),
                child: Stack(
                    clipBehavior: Clip.none,
                    children: switch (widget.slide) {
                      0 => art.backup(),
                      1 => art.learn(),
                      2 => art.sos(),
                      _ => art.ai(),
                    }),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Builds one frame of a slide. [t] is the loop position 0..1, or null to
/// draw the still, finished frame.
class _Art {
  const _Art(this.t);

  final double? t;

  static const _small = TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700);
  static const _muted = TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary);
  static const _body = TextStyle(fontSize: 13, height: 18 / 13);

  /// 0..1..0 twice per loop, eased; 1 when still.
  double get _fill => t == null ? 1 : 0.5 - 0.5 * math.cos(t! * 4 * math.pi);

  List<Widget> backup() => [
        _blob(36, 20, 270, AppColors.blush),
        _blob(250, 8, 64, AppColors.accent),
        _blob(18, 232, 36, AppColors.primary),
        _card(
          left: 8,
          top: 34,
          width: 200,
          angle: -5,
          phase: 0,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _tile(Icons.savings_outlined, 40),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Finance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  Text('Budgeting basics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            _progress(0.66),
          ]),
        ),
        _card(
          left: 128,
          top: 128,
          width: 206,
          angle: 4,
          phase: 0.33,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                child: const Text('DN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              const Flexible(child: Text('Dewi · Her Space', style: _small, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            const Text('Anyone else nervous before their first salary talk?', style: _body),
            const SizedBox(height: 8),
            const Row(children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 15, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Flexible(child: Text('24 replies', style: _muted, overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
        _card(
          left: 30,
          top: 236,
          width: 196,
          angle: -2,
          phase: 0.66,
          radius: 30,
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: const Text('SOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Ibu and Rina are ready if you need them', style: _small)),
          ]),
        ),
      ];

  List<Widget> learn() => [
        _blob(26, 26, 290, AppColors.blush),
        _blob(10, 40, 48, AppColors.accent),
        _card(
          left: 56,
          top: 40,
          width: 230,
          angle: -2,
          phase: 0,
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 104,
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Icon(Icons.work_outline_rounded, size: 40, color: AppColors.primary)),
            ),
            const SizedBox(height: 8),
            _tag('Career'),
            const SizedBox(height: 6),
            const Text('Negotiating your salary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _progress(0.75)),
              const SizedBox(width: 8),
              const Text('3 of 4', style: _muted),
            ]),
          ]),
        ),
        _card(
          left: 238,
          top: 6,
          width: 92,
          angle: 6,
          phase: 0.33,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_outlined, size: 22, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text('Certificate', style: _small),
          ]),
        ),
        _pill(left: 6, top: 262, angle: -3, phase: 0.66, icon: Icons.check_rounded, label: 'Lesson done · 7 min', filled: true),
        _pill(left: 206, top: 270, angle: 3, phase: 0, icon: Icons.download_done_rounded, label: 'Saved offline'),
      ];

  List<Widget> sos() {
    final sweep = t == null ? 0.33 : (t! * 2) % 1;
    return [
      _blob(31, 10, 280, AppColors.dangerTint),
      if (t != null) ...[_pulse((t! * 2.5) % 1), _pulse((t! * 2.5 + 0.5) % 1)],
      Positioned(left: 71, top: 50, width: 200, height: 200, child: CustomPaint(painter: _RingPainter(sweep))),
      Positioned(
        left: 106,
        top: 85,
        width: 130,
        height: 130,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('SOS', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 1.8, color: Colors.white)),
            Text('Hold 3 sec', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dangerTint)),
          ]),
        ),
      ),
      _card(
        left: 176,
        top: 0,
        width: 162,
        angle: 4,
        phase: 0.33,
        radius: 18,
        tail: true,
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.sms_outlined, size: 15, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Flexible(child: Text('To: Ibu, Rina', style: _muted, overflow: TextOverflow.ellipsis)),
          ]),
          SizedBox(height: 6),
          Text.rich(
            TextSpan(text: 'I need help. This is where I am: ', children: [
              TextSpan(text: 'maps.google.com/?q=-6.24,106.80', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
            style: TextStyle(fontSize: 12, height: 16 / 12),
          ),
        ]),
      ),
      _pill(left: 4, top: 252, angle: -3, phase: 0.66, icon: Icons.wifi_off_rounded, label: 'Works without internet'),
    ];
  }

  List<Widget> ai() => [
        _blob(36, 24, 270, AppColors.blush),
        _blob(280, 210, 44, AppColors.accent),
        Positioned(
          right: 8,
          top: 14,
          child: _float(
            angle: 2,
            phase: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [BoxShadow(color: AppColors.primaryVariant.withValues(alpha: 0.25), blurRadius: 26, offset: const Offset(0, 12))],
              ),
              child: const Text('How do I ask for a raise?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ),
        _card(
          left: 10,
          top: 82,
          width: 268,
          angle: -2,
          phase: 0.33,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Flexible(child: Text('Empuan AI', style: _small, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            const Text('Start with what you’ve delivered this year, then name a number. Three steps that help:', style: _body),
            const SizedBox(height: 6),
            _bullet('Check the pay range for your role'),
            _bullet('Book a short meeting, not a hallway chat'),
            const SizedBox(height: 8),
            _typing(),
          ]),
        ),
        _card(
          left: 92,
          top: 250,
          width: 214,
          angle: 3,
          phase: 0.66,
          radius: 16,
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(children: [
            _tile(Icons.menu_book_outlined, 32),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Related course', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                Text('Negotiating your salary', style: _small),
              ]),
            ),
          ]),
        ),
      ];

  // Pieces

  Widget _blob(double left, double top, double size, Color color) => Positioned(
        left: left,
        top: top,
        width: size,
        height: size,
        child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      );

  /// Bobs up and down by 7 px, offset by [phase] so cards don't move together.
  Widget _float({required double angle, required double phase, required Widget child}) {
    final lift = t == null ? 0.0 : -7 * (0.5 - 0.5 * math.cos((t! + phase) * 2 * math.pi));
    return Transform.translate(
      offset: Offset(0, lift),
      child: Transform.rotate(angle: angle * math.pi / 180, child: child),
    );
  }

  Widget _card({
    required double left,
    required double top,
    required double width,
    required double angle,
    required double phase,
    required Widget child,
    double radius = 18,
    bool tail = false,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: _float(
        angle: angle,
        phase: phase,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: tail
                ? BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius),
                    bottomRight: const Radius.circular(4),
                  )
                : BorderRadius.circular(radius),
            boxShadow: [BoxShadow(color: AppColors.primaryVariant.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _pill({
    required double left,
    required double top,
    required double angle,
    required double phase,
    required IconData icon,
    required String label,
    bool filled = false,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: _float(
        angle: angle,
        phase: phase,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: AppColors.primaryVariant.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: filled ? AppColors.primary : AppColors.blush, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: filled ? Colors.white : AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(label, style: _small),
          ]),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(size * 0.28)),
        child: Icon(icon, size: size * 0.5, color: AppColors.primary),
      );

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
      );

  /// Fills from 12% to [target] and back.
  Widget _progress(double target) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Container(
          height: 6,
          color: AppColors.blush,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 0.12 + (target - 0.12) * _fill,
            child: Container(color: AppColors.primary),
          ),
        ),
      );

  Widget _pulse(double p) => Positioned(
        left: 91,
        top: 70,
        width: 160,
        height: 160,
        child: Opacity(
          opacity: 0.6 * (1 - p),
          child: Transform.scale(
            scale: 0.85 + 0.6 * p,
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.danger, width: 2)),
            ),
          ),
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 16 / 12))),
        ]),
      );

  Widget _typing() => Row(children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(
                alpha: t == null ? 1 : 0.3 + 0.7 * (0.5 - 0.5 * math.cos(((t! * 5) - i * 0.17) * 2 * math.pi)),
              ),
              shape: BoxShape.circle,
            ),
          ),
      ]);
}

/// The SOS countdown ring: a faint track and a sweep from the top.
class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width * 0.44);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, stroke..color = AppColors.danger.withValues(alpha: 0.15));
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, stroke..color = AppColors.danger);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../ui/em_ui.dart';

/// The real widgets the app tour points at.
enum TourTarget { sos, safety, askAi, learn, space, avatar }

/// Keys on the real widgets, one set per shell, so the tour can measure where
/// they are on this screen, in this orientation, at this text size.
class TourTargets {
  final sos = GlobalKey(debugLabel: 'tour: SOS face');
  final safety = GlobalKey(debugLabel: 'tour: Safety tab');
  final askAi = GlobalKey(debugLabel: 'tour: Ask Empuan AI');
  final learn = GlobalKey(debugLabel: 'tour: Learn tab');
  final space = GlobalKey(debugLabel: 'tour: Space tab');
  final avatar = GlobalKey(debugLabel: 'tour: avatar');

  GlobalKey operator [](TourTarget target) => switch (target) {
        TourTarget.sos => sos,
        TourTarget.safety => safety,
        TourTarget.askAi => askAi,
        TourTarget.learn => learn,
        TourTarget.space => space,
        TourTarget.avatar => avatar,
      };
}

/// Lets Me › App tour ask the shell to run the tour again.
class AppTour {
  static final replays = ValueNotifier<int>(0);

  static void replay() => replays.value++;
}

/// Where the tour is. The shell listens to switch the SOS button into
/// practice mode on the first step.
class AppTourController extends ChangeNotifier {
  static const steps = 5;

  int _step = 0;
  bool _practiced = false;
  bool _closed = false;

  int get step => _step;
  bool get practiced => _practiced;
  bool get isLast => _step == steps - 1;

  /// Non-null only on the first step until the user has practised once. While
  /// set, the shell passes it to the SOS button so a completed hold lands here
  /// instead of starting the SOS flow.
  VoidCallback? get practice => !_closed && _step == 0 && !_practiced ? _completePractice : null;

  void _completePractice() {
    if (_closed || _step != 0 || _practiced) return;
    _practiced = true;
    notifyListeners();
  }

  /// Moves on from [from]. Taps on a card that is already fading out are ignored.
  void next(int from) {
    if (_closed || from != _step || isLast) return;
    _step++;
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}

class _Step {
  const _Step({required this.label, required this.title, required this.body, required this.targets, this.practice = false});

  final String label;
  final String title;

  /// Text runs; the bold ones are tab and menu names.
  final List<(String, bool)> body;
  final List<TourTarget> targets;

  /// Shows "Try it now: hold SOS".
  final bool practice;
}

const _steps = [
  _Step(
    label: '1 of 5',
    title: 'Your SOS button',
    body: [('Hold it for 3 seconds to alert your trusted contacts with your location. A quick tap does nothing, so it won’t go off by accident.', false)],
    targets: [TourTarget.sos],
    practice: true,
  ),
  _Step(
    label: '2 of 5',
    title: 'Safety tools',
    body: [('Choose who gets your SOS, start a fake call to get out of an uncomfortable situation, or play a loud siren.', false)],
    targets: [TourTarget.safety],
  ),
  _Step(
    label: '3 of 5',
    title: 'Ask Empuan AI',
    body: [
      (
        'Ask privately about safety, work, money, health or relationships. It can point you to courses, articles and safety tools. Answers can be wrong, so check anything important.',
        false
      ),
    ],
    targets: [TourTarget.askAi],
  ),
  _Step(
    label: '4 of 5',
    title: 'Learn and Her Space',
    body: [
      ('Learn', true),
      (' has short courses with certificates, plus articles from Her Voice. ', false),
      ('Her Space', true),
      (' is where women ask questions and share wins. You can report or block anyone.', false),
    ],
    targets: [TourTarget.learn, TourTarget.space],
  ),
  _Step(
    label: '5 of 5',
    title: 'Your profile',
    body: [
      ('Edit your details, manage trusted contacts and fake-call callers, see your certificates, or replay this tour any time from ', false),
      ('Me › App tour', true),
      ('.', false),
    ],
    targets: [TourTarget.avatar],
  ),
];

const _practiceDone = _Step(
  label: '1 of 5 · Practice done',
  title: 'That’s all it takes',
  body: [
    (
      'When it’s real, the same hold starts a 5-second countdown you can cancel, then opens your messages app with a help text and your location. You press send.',
      false
    ),
  ],
  targets: [TourTarget.sos],
);

_Step _stepFor(AppTourController c) => c.step == 0 && c.practiced ? _practiceDone : _steps[c.step];

/// The cut-out around a target, padded so the white ring doesn't touch it.
RRect _holeFor(TourTarget target, Rect r) {
  switch (target) {
    case TourTarget.sos:
    case TourTarget.avatar:
      final hole = r.inflate(target == TourTarget.sos ? 7 : 6);
      return RRect.fromRectAndRadius(hole, Radius.circular(hole.shortestSide / 2));
    case TourTarget.safety:
    case TourTarget.learn:
    case TourTarget.space:
      final hole = Rect.fromCenter(center: r.center, width: math.max(48, math.min(r.width - 4, 70)), height: r.height + 8);
      return RRect.fromRectAndRadius(hole, const Radius.circular(18));
    case TourTarget.askAi:
      return RRect.fromRectAndRadius(r.inflate(4), const Radius.circular(24));
  }
}

List<RRect> _lerpHoles(List<RRect> a, List<RRect> b, double t) {
  if (t >= 1 || a.isEmpty || b.isEmpty) return b;
  // One hole splits into two (or two merge into one) by sharing the last.
  final n = math.max(a.length, b.length);
  return [
    for (var i = 0; i < n; i++) RRect.lerp(a[math.min(i, a.length - 1)], b[math.min(i, b.length - 1)], t)!,
  ];
}

/// Dark scrim with rounded cut-outs around the real widgets, and a card that
/// explains each one. Taps on the scrim do nothing; only the card's buttons
/// act. On the practice step the SOS face alone lets touches through.
class AppTourOverlay extends StatefulWidget {
  const AppTourOverlay({super.key, required this.controller, required this.targets, required this.onClose});

  final AppTourController controller;
  final TourTargets targets;

  /// Skip tour or Done.
  final VoidCallback onClose;

  @override
  State<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<AppTourOverlay> with TickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(vsync: this, duration: EmMotion.medium);

  // Moves the cut-outs from one step's targets to the next.
  late final AnimationController _move = AnimationController(vsync: this, duration: EmMotion.slow, value: 1);
  late final Animation<double> _moveCurve = CurvedAnimation(parent: _move, curve: EmMotion.enter);

  List<RRect> _from = const [];
  List<RRect> _to = const [];
  Rect? _sosFace;
  bool _measured = false;
  late int _step = widget.controller.step;
  bool _started = false;

  List<RRect> get _holes => _lerpHoles(_from, _to, _moveCurve.value);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
    _watchLayout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (EmMotion.reduced(context)) {
      _appear.value = 1;
    } else {
      _appear.forward();
    }
    _bringIntoView();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _appear.dispose();
    _move.dispose();
    super.dispose();
  }

  /// Targets move: content loads above the AI card, the list scrolls into
  /// place, the phone rotates. Measuring after every frame keeps the holes on
  /// them. This never schedules a frame itself, so an idle tour costs nothing.
  void _watchLayout() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
      _watchLayout();
    });
  }

  void _measure() {
    final overlay = context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) return;
    final toOverlay = Matrix4.tryInvert(overlay.getTransformTo(null));
    if (toOverlay == null) return;

    Rect? rectOf(GlobalKey key) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return null;
      return MatrixUtils.transformRect(toOverlay.multiplied(box.getTransformTo(null)), Offset.zero & box.size);
    }

    final holes = <RRect>[
      for (final target in _stepFor(widget.controller).targets)
        if (rectOf(widget.targets[target]) case final rect?) _holeFor(target, rect),
    ];
    final face = rectOf(widget.targets.sos);
    if (_measured && listEquals(holes, _to) && face == _sosFace) return;
    setState(() {
      // The very first measurement places the holes without moving them.
      if (!_measured) _from = holes;
      _measured = true;
      _to = holes;
      _sosFace = face;
    });
  }

  void _onController() {
    final step = widget.controller.step;
    if (step != _step) {
      _from = _holes;
      _step = step;
      _bringIntoView();
      if (EmMotion.reduced(context)) {
        _move.value = 1;
      } else {
        _move.forward(from: 0);
      }
      _measure();
    }
    setState(() {});
  }

  /// Home scrolls; make sure the AI card or the avatar is on screen.
  void _bringIntoView() {
    final target = switch (widget.controller.step) {
      2 => widget.targets.askAi,
      4 => widget.targets.avatar,
      _ => null,
    };
    final targetContext = target?.currentContext;
    if (targetContext == null) return;
    final duration = EmMotion.reduced(context) ? Duration.zero : EmMotion.medium;
    // Each call is a no-op unless the target is cut off at that end.
    for (final policy in [ScrollPositionAlignmentPolicy.keepVisibleAtStart, ScrollPositionAlignmentPolicy.keepVisibleAtEnd]) {
      Scrollable.ensureVisible(targetContext, duration: duration, curve: EmMotion.enter, alignmentPolicy: policy).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final step = _stepFor(c);
    final index = c.step;
    final reduced = EmMotion.reduced(context);
    final media = MediaQuery.of(context);
    final insets = media.padding.copyWith(bottom: math.max(media.padding.bottom, media.viewInsets.bottom));

    // Practice: only the SOS face lets touches through, to the real button.
    final passThrough = c.practice != null ? _sosFace : null;

    return FadeTransition(
      opacity: _appear,
      // Sits beside the Scaffold, not in it: give the card text styles and ink.
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _TourBarrier(passThrough: passThrough),
            IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _moveCurve,
                  builder: (_, __) => CustomPaint(painter: _ScrimPainter(_holes)),
                ),
              ),
            ),
            if (c.step == 0 && c.practiced && _to.isNotEmpty) _PracticeDoneFace(rect: _to.first.outerRect),
            if (_measured)
              AnimatedSwitcher(
                duration: reduced ? Duration.zero : EmMotion.medium,
                switchInCurve: EmMotion.enter,
                switchOutCurve: EmMotion.exit,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  // The outgoing card can't be tapped or read while it fades.
                  child: AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (_, child) {
                      final leaving = animation.status == AnimationStatus.reverse;
                      return IgnorePointer(ignoring: leaving, child: ExcludeSemantics(excluding: leaving, child: child));
                    },
                  ),
                ),
                child: _TourCardLayout(
                  key: ValueKey((c.step, c.practiced)),
                  holes: [for (final h in _to) h.outerRect],
                  insets: insets,
                  card: _TourCard(
                    step: step,
                    index: index,
                    isLast: c.isLast,
                    onNext: () => c.isLast ? widget.onClose() : c.next(index),
                    onSkip: widget.onClose,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Swallows every touch except inside [passThrough], which falls through to
/// the real widget underneath.
class _TourBarrier extends LeafRenderObjectWidget {
  const _TourBarrier({this.passThrough});

  final Rect? passThrough;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTourBarrier(passThrough);

  @override
  void updateRenderObject(BuildContext context, _RenderTourBarrier renderObject) => renderObject.passThrough = passThrough;
}

class _RenderTourBarrier extends RenderBox {
  _RenderTourBarrier(this.passThrough);

  Rect? passThrough;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => !(passThrough?.contains(position) ?? false);
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.holes);

  final List<RRect> holes;

  static const _scrim = Color(0xBD180910);
  static const _ring = Color(0xF2FFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final hole in holes) {
      scrim.addRRect(hole);
    }
    canvas.drawPath(scrim, Paint()..color = _scrim);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _ring;
    for (final hole in holes) {
      canvas.drawRRect(hole.inflate(1.5), ring);
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => !listEquals(old.holes, holes);
}

/// After a practice hold: a full white ring and a check over the SOS face.
class _PracticeDoneFace extends StatelessWidget {
  const _PracticeDoneFace({required this.rect});

  final Rect rect;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: EmMotion.reduced(context) ? 1 : 0.6, end: 1),
            duration: EmMotion.slow,
            curve: EmMotion.pop,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Container(
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts the card above or below the holes, whichever side has more room, and
/// a caret pointing at each hole. Keeps it inside the safe area; a card too
/// tall for the room scrolls.
class _TourCardLayout extends StatelessWidget {
  const _TourCardLayout({super.key, required this.holes, required this.insets, required this.card});

  final List<Rect> holes;
  final EdgeInsets insets;
  final Widget card;

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _CardLayoutDelegate(holes: holes, insets: insets),
      children: [
        for (var i = 0; i < holes.length; i++) LayoutId(id: i, child: const _Caret()),
        LayoutId(id: _CardLayoutDelegate.card, child: card),
      ],
    );
  }
}

class _CardLayoutDelegate extends MultiChildLayoutDelegate {
  _CardLayoutDelegate({required this.holes, required this.insets});

  final List<Rect> holes;
  final EdgeInsets insets;

  static const card = 'card';
  static const _margin = 16.0;
  static const _gap = 16.0;
  static const _maxWidth = 440.0;
  static const _caret = 16.0;

  @override
  void performLayout(Size size) {
    final left = insets.left + _margin;
    final right = size.width - insets.right - _margin;
    final top = insets.top + 8;
    final bottom = size.height - insets.bottom - 8;
    final width = math.max(0.0, math.min(right - left, _maxWidth));
    final height = math.max(0.0, bottom - top);

    if (holes.isEmpty) {
      // The target isn't on screen: centre the card so the tour can go on.
      final size = layoutChild(card, BoxConstraints(minWidth: width, maxWidth: width, maxHeight: height));
      positionChild(card, Offset(left + (right - left - width) / 2, top + (height - size.height) / 2));
      return;
    }

    final target = holes.reduce((a, b) => a.expandToInclude(b));
    final above = target.top - _gap - top;
    final below = bottom - target.bottom - _gap;
    final putBelow = below >= above;
    final room = math.min(height, math.max(putBelow ? below : above, 120.0));
    final cardSize = layoutChild(card, BoxConstraints(minWidth: width, maxWidth: width, maxHeight: room));

    final x = (target.center.dx - width / 2).clamp(left, math.max(left, right - width)).toDouble();
    final y = (putBelow ? target.bottom + _gap : target.top - _gap - cardSize.height).clamp(top, math.max(top, bottom - cardSize.height)).toDouble();
    positionChild(card, Offset(x, y));

    for (var i = 0; i < holes.length; i++) {
      layoutChild(i, BoxConstraints.tight(const Size.square(_caret)));
      final cx = holes[i].center.dx.clamp(x + 24, math.max(x + 24, x + width - 24));
      // Centred on the card's edge, nudged 1px in so no seam shows.
      final cy = putBelow ? y + 1 : y + cardSize.height - 1;
      positionChild(i, Offset(cx - _caret / 2, cy - _caret / 2));
    }
  }

  @override
  bool shouldRelayout(_CardLayoutDelegate old) => !listEquals(old.holes, holes) || old.insets != insets;
}

class _Caret extends StatelessWidget {
  const _Caret();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(3))),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.step, required this.index, required this.isLast, required this.onNext, required this.onSkip});

  final _Step step;
  final int index;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.textSecondary);
    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'App tour, step ${index + 1} of ${AppTourController.steps}',
      child: FocusScope(
        autofocus: true,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x47000000), blurRadius: 36, offset: Offset(0, 14))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only the text scrolls when space is short; the buttons stay put.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          step.label.toUpperCase(),
                          style: const TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, letterSpacing: 0.72, color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Semantics(header: true, child: Text(step.title, style: text.titleMedium)),
                      const SizedBox(height: 10),
                      Text.rich(
                        TextSpan(children: [
                          for (final (run, bold) in step.body)
                            TextSpan(
                              text: run,
                              style: bold ? const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary) : null,
                            ),
                        ]),
                        style: muted,
                      ),
                      if (step.practice) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            children: [
                              Icon(Icons.touch_app_outlined, size: 18, color: AppColors.danger),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Try it now: hold SOS. This is practice, nothing is sent.',
                                  style: TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600, color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Skip tour'),
                    ),
                  const Spacer(),
                  EmButton(label: isLast ? 'Done' : 'Next', small: true, expand: false, onPressed: onNext),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

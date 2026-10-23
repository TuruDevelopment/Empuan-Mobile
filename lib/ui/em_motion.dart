import 'package:flutter/material.dart';

import '../styles/style.dart';

/// Shared motion values so every screen moves the same way.
class EmMotion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);

  /// Things entering the screen.
  static const enter = Curves.easeOutCubic;

  /// Things leaving or changing state.
  static const exit = Curves.easeInCubic;

  /// Small playful moments: likes, success checks.
  static const pop = Curves.elasticOut;

  /// Gap between items in a staggered list.
  static const stagger = Duration(milliseconds: 45);

  /// True when the user asked the system to reduce motion. Animations should
  /// then jump to their end state.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Delay for the [index]th item in a list, capped so long lists don't lag.
  static Duration staggerFor(int index) => stagger * index.clamp(0, 8);
}

/// Fades and slides its child in once when first built.
///
/// Use [index] for staggered lists: each item starts a little later.
class EmFadeSlideIn extends StatefulWidget {
  const EmFadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 16),
    this.duration = EmMotion.slow,
  });

  final Widget child;
  final int index;
  final Duration delay;

  /// Starting offset in logical pixels.
  final Offset offset;
  final Duration duration;

  @override
  State<EmFadeSlideIn> createState() => _EmFadeSlideInState();
}

class _EmFadeSlideInState extends State<EmFadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: EmMotion.enter);
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
    final wait = widget.delay + EmMotion.staggerFor(widget.index);
    if (wait == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(wait, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: widget.offset * (1 - _t.value), child: child),
      ),
    );
  }
}

/// Shrinks slightly while pressed, for cards and buttons.
class EmPressable extends StatefulWidget {
  const EmPressable({super.key, required this.child, this.enabled = true, this.scale = 0.97});

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<EmPressable> createState() => _EmPressableState();
}

class _EmPressableState extends State<EmPressable> {
  bool _down = false;

  void _set(bool down) {
    if (!widget.enabled || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || EmMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: EmMotion.fast,
        curve: _down ? EmMotion.exit : EmMotion.enter,
        child: widget.child,
      ),
    );
  }
}

/// Grey placeholder block with a soft moving sheen, used while content loads.
class EmSkeleton extends StatefulWidget {
  const EmSkeleton({super.key, this.width, required this.height, this.radius = 12});

  final double? width;
  final double height;
  final double radius;

  @override
  State<EmSkeleton> createState() => _EmSkeletonState();
}

class _EmSkeletonState extends State<EmSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!EmMotion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final x = _c.value * 3 - 1;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(x - 1, 0),
                end: Alignment(x + 1, 0),
                colors: const [AppColors.blush, Color(0xFFFBF3F5), AppColors.blush],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A list-shaped loading placeholder: [count] rows of thumbnail + two lines.
class EmSkeletonList extends StatelessWidget {
  const EmSkeletonList({super.key, this.count = 4, this.thumbnail = 64, this.padding = const EdgeInsets.all(20)});

  final int count;
  final double thumbnail;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => Row(
          children: [
            if (thumbnail > 0) ...[EmSkeleton(width: thumbnail, height: thumbnail, radius: 14), const SizedBox(width: 14)],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmSkeleton(height: 14, width: 120),
                  SizedBox(height: 10),
                  EmSkeleton(height: 16),
                  SizedBox(height: 8),
                  EmSkeleton(height: 16, width: 180),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swaps between values (counts, labels) with a quick vertical slide.
class EmAnimatedSwap extends StatelessWidget {
  const EmAnimatedSwap({super.key, required this.child, required this.valueKey});

  final Widget child;
  final Object valueKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
      switchInCurve: EmMotion.enter,
      switchOutCurve: EmMotion.exit,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(a), child: child),
      ),
      child: KeyedSubtree(key: ValueKey(valueKey), child: child),
    );
  }
}

/// Cross-fades between loading, error, empty and content states.
class EmStateSwitcher extends StatelessWidget {
  const EmStateSwitcher({super.key, required this.child, required this.stateKey});

  final Widget child;
  final Object stateKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
      switchInCurve: EmMotion.enter,
      switchOutCurve: EmMotion.exit,
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}

/// Heart that pops when it becomes filled.
class EmLikeIcon extends StatelessWidget {
  const EmLikeIcon({super.key, required this.liked, this.size = 18, this.color = AppColors.danger});

  final bool liked;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(liked),
      tween: Tween(begin: liked && !EmMotion.reduced(context) ? 0.6 : 1, end: 1),
      duration: EmMotion.slow,
      curve: EmMotion.pop,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: size, color: liked ? color : AppColors.textSecondary),
    );
  }
}

/// Route with the app's standard forward-fade transition, for cases that
/// can't use the theme default (e.g. pushReplacement to a sibling screen).
Route<T> emRoute<T>(Widget screen, {bool fullscreenDialog = false}) =>
    MaterialPageRoute<T>(builder: (_) => screen, fullscreenDialog: fullscreenDialog);

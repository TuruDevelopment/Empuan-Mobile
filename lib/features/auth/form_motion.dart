import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';

/// Staggered entrance for a list item. It also keeps itself alive inside a
/// lazy list, so scrolling it away and back doesn't replay the entrance.
class StaggerItem extends StatefulWidget {
  const StaggerItem({super.key, required this.index, required this.child, this.delay = Duration.zero});

  final int index;
  final Duration delay;
  final Widget child;

  @override
  State<StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<StaggerItem> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return EmFadeSlideIn(index: widget.index, delay: widget.delay, child: widget.child);
  }
}

/// Wraps each block of a form in a [StaggerItem]. Spacers aren't counted, so
/// the blocks follow each other evenly.
///
/// Keep the list the same length between builds (use [AnimatedReveal] for
/// optional parts) so lazy lists don't re-create items and replay them.
List<Widget> staggered(List<Widget> children, {Duration delay = Duration.zero}) {
  var i = 0;
  return [
    for (final child in children) child is SizedBox ? child : StaggerItem(index: i++, delay: delay, child: child),
  ];
}

/// Shows [child] with a fade and short slide, and collapses smoothly when it
/// becomes null. A new [switchKey] cross-fades to the new content.
class AnimatedReveal extends StatelessWidget {
  const AnimatedReveal({super.key, this.child, this.switchKey, this.offset = const Offset(0, -0.2)});

  final Widget? child;
  final Object? switchKey;

  /// Starting offset as a fraction of the child's size.
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final duration = EmMotion.reduced(context) ? Duration.zero : EmMotion.medium;
    return AnimatedSize(
      duration: duration,
      curve: EmMotion.enter,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: EmMotion.enter,
        switchOutCurve: EmMotion.exit,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          fit: StackFit.passthrough,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween(begin: offset, end: Offset.zero).animate(a), child: child),
        ),
        child: child == null
            ? const SizedBox(key: ValueKey('em-reveal-empty'), width: double.infinity)
            : KeyedSubtree(key: ValueKey(switchKey ?? 'em-reveal-shown'), child: child!),
      ),
    );
  }
}

/// Inline form error that fades and slides in under the field above it.
class AnimatedFormMessage extends StatelessWidget {
  const AnimatedFormMessage({super.key, required this.message, this.padding = EdgeInsets.zero, this.fontSize = 13});

  final String? message;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedReveal(
      switchKey: message,
      child: message == null
          ? null
          : Padding(
              padding: padding,
              child: Semantics(
                liveRegion: true,
                child: Text(message!, style: TextStyle(color: AppColors.danger, fontSize: fontSize, fontWeight: FontWeight.w600)),
              ),
            ),
    );
  }
}

/// Password rule line whose icon and colour change smoothly as the rule is met.
class AnimatedCheckLine extends StatelessWidget {
  const AnimatedCheckLine({super.key, required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.primary : AppColors.textSecondary;
    final duration = EmMotion.reduced(context) ? Duration.zero : EmMotion.medium;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: AnimatedSwitcher(
              duration: duration,
              switchInCurve: EmMotion.enter,
              switchOutCurve: EmMotion.exit,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: Tween(begin: 0.5, end: 1.0).animate(a), child: child),
              ),
              child: Icon(met ? Icons.check_rounded : Icons.circle_outlined, key: ValueKey(met), size: 16, color: color),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: AnimatedDefaultTextStyle(
              duration: duration,
              curve: EmMotion.enter,
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step indicator whose segments fill from the left when the step changes.
/// The current segment also fills on first appearance, so each onboarding
/// screen shows the step it just reached.
class AnimatedStepBar extends StatelessWidget {
  const AnimatedStepBar({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final duration = EmMotion.reduced(context) ? Duration.zero : EmMotion.slow;
    return Semantics(
      label: 'Step $step of $total',
      child: Row(
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(3)),
                child: TweenAnimationBuilder<double>(
                  // begin only applies on first build; later changes animate
                  // from wherever the segment currently is.
                  tween: Tween(begin: i == step ? 0 : (i <= step ? 1 : 0), end: i <= step ? 1 : 0),
                  duration: duration,
                  curve: EmMotion.enter,
                  builder: (_, fill, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fill,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color.lerp(AppColors.surfaceAlt, AppColors.primary, fill),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cross-fades a button between its enabled and disabled look, which
/// [EmButton] otherwise swaps instantly. The fading-out copy ignores taps.
class AnimatedEnabled extends StatelessWidget {
  const AnimatedEnabled({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
      switchInCurve: EmMotion.enter,
      switchOutCurve: EmMotion.exit,
      transitionBuilder: (child, a) {
        final outgoing = child.key != ValueKey(enabled);
        return FadeTransition(
          opacity: a,
          child: IgnorePointer(ignoring: outgoing, child: ExcludeSemantics(excluding: outgoing, child: child)),
        );
      },
      child: KeyedSubtree(key: ValueKey(enabled), child: child),
    );
  }
}

/// Horizontal "next step" transition for an [AnimatedSwitcher]: the new child
/// fades in from the right (or left when [forward] is false) while the old one
/// fades out the other way.
AnimatedSwitcherTransitionBuilder sharedAxisTransition({required Object currentKey, bool forward = true}) {
  final dir = forward ? 1.0 : -1.0;
  return (child, a) {
    final incoming = child.key == currentKey;
    // The old child clears out quickly so the two never read on top of each other.
    final fade = CurveTween(curve: incoming ? const Interval(0.3, 1) : const Interval(0.6, 1));
    final slide = Tween(begin: Offset((incoming ? 0.12 : -0.12) * dir, 0), end: Offset.zero).chain(CurveTween(curve: EmMotion.enter));
    return FadeTransition(
      opacity: a.drive(fade),
      child: SlideTransition(position: a.drive(slide), child: child),
    );
  };
}

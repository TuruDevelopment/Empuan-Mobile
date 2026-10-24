import 'package:flutter/material.dart';

import '../ui/em_motion.dart';

/// Fades and folds its child away when [visible] turns false, so removed list
/// items leave smoothly. The parent removes the item after [EmMotion.medium].
class CollapseOut extends StatefulWidget {
  const CollapseOut({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<CollapseOut> createState() => _CollapseOutState();
}

class _CollapseOutState extends State<CollapseOut> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: EmMotion.medium, value: widget.visible ? 1 : 0);
  late final _t = CurvedAnimation(parent: _c, curve: EmMotion.enter, reverseCurve: EmMotion.exit);

  @override
  void didUpdateWidget(CollapseOut old) {
    super.didUpdateWidget(old);
    if (old.visible == widget.visible) return;
    if (EmMotion.reduced(context)) {
      _c.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _t,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _t, child: widget.child),
    );
  }
}

/// Removes items after their [CollapseOut] animation has played.
Future<void> afterCollapse(BuildContext context, VoidCallback remove) async {
  if (!EmMotion.reduced(context)) await Future<void>.delayed(EmMotion.medium);
  remove();
}

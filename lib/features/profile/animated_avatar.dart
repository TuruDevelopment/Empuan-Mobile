import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';

/// [EmAvatar] whose initials slide in when the name changes (e.g. when the
/// profile arrives, or while editing the name). The circle itself stays put.
class AnimatedAvatar extends StatelessWidget {
  const AnimatedAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
      child: EmAnimatedSwap(
        valueKey: initials,
        child: Text(
          initials,
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: size * 0.36),
        ),
      ),
    );
  }
}

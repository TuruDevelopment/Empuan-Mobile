import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';

/// Equal tabs on a blush track; a white pill slides to the selected one.
class LearnSegmentedControl extends StatelessWidget {
  const LearnSegmentedControl({super.key, required this.labels, required this.selected, required this.onChanged});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final count = labels.length;
    final x = count < 2 ? 0.0 : -1 + 2 * selected / (count - 1);
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(14)),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(x, 0),
            duration: EmMotion.reduced(context) ? Duration.zero : EmMotion.medium,
            curve: EmMotion.enter,
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [BoxShadow(color: Color(0x1F4B0E28), blurRadius: 3, offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  child: Semantics(
                    selected: i == selected,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

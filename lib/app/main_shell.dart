import 'package:flutter/material.dart';

import '../features/home/home_tab.dart';
import '../features/learn/learn_tab.dart';
import '../features/safety/safety_tab.dart';
import '../features/safety/sos_flow.dart';
import '../features/space/space_tab.dart';
import '../ui/em_ui.dart';

enum AppTab { home, learn, safety, space }

/// Lets any screen inside the shell switch tabs, e.g. "See all" on Home.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.goTo, required super.child});

  final void Function(AppTab tab) goTo;

  static ShellScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late AppTab _tab = widget.initialTab;
  final Set<AppTab> _built = {};

  void _goTo(AppTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    _built.add(_tab);
    Widget page(AppTab tab, Widget Function() build) =>
        _built.contains(tab) ? build() : const SizedBox.shrink();

    return ShellScope(
      goTo: _goTo,
      child: PopScope(
        canPop: _tab == AppTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goTo(AppTab.home);
        },
        child: Scaffold(
          body: Column(
            children: [
              const SosActiveBanner(),
              Expanded(
                // Tabs keep their state in the IndexedStack; the switch itself
                // is a short fade-up so the change of place is visible.
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_tab),
                  tween: Tween(begin: EmMotion.reduced(context) ? 1 : 0, end: 1),
                  duration: EmMotion.medium,
                  curve: EmMotion.enter,
                  builder: (_, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
                  ),
                  child: IndexedStack(
                    index: _tab.index,
                    children: [
                      page(AppTab.home, () => const HomeTab()),
                      page(AppTab.learn, () => const LearnTab()),
                      page(AppTab.safety, () => const SafetyTab()),
                      page(AppTab.space, () => const SpaceTab()),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _TabBar(current: _tab, onSelect: _goTo),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.only(top: 8, bottom: bottom > 0 ? bottom : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _item(AppTab.home, Icons.home_outlined, Icons.home_rounded, 'Home'),
          _item(AppTab.learn, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Learn'),
          Expanded(
            child: SizedBox(
              height: 52,
              child: OverflowBox(
                maxHeight: 96,
                alignment: Alignment.bottomCenter,
                child: Builder(builder: (ctx) => SosHoldButton(onTriggered: () => startSosFlow(ctx))),
              ),
            ),
          ),
          _item(AppTab.safety, Icons.shield_outlined, Icons.shield_rounded, 'Safety'),
          _item(AppTab.space, Icons.forum_outlined, Icons.forum_rounded, 'Space'),
        ],
      ),
    );
  }

  Widget _item(AppTab tab, IconData icon, IconData activeIcon, String label) {
    final selected = tab == current;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: () => onSelect(tab),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: EmMotion.medium,
                  curve: EmMotion.enter,
                  width: 56,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.blush : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: EmMotion.medium,
                    curve: EmMotion.enter,
                    child: Icon(selected ? activeIcon : icon, color: color, size: 22),
                  ),
                ),
                const SizedBox(height: 2),
                ExcludeSemantics(
                  child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

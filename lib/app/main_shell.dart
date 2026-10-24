import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../features/home/home_tab.dart';
import '../features/learn/learn_tab.dart';
import '../features/safety/safety_tab.dart';
import '../features/safety/sos_flow.dart';
import '../features/space/space_tab.dart';
import '../features/tour/app_tour.dart';
import '../features/tour/intro_prefs.dart';
import '../features/tour/whats_new_screen.dart';
import '../ui/em_ui.dart';

enum AppTab { home, learn, safety, space }

/// Lets any screen inside the shell switch tabs, e.g. "See all" on Home.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.goTo, this.tourTargets, required super.child});

  final void Function(AppTab tab) goTo;

  /// Keys the app tour measures; Home puts two of them on its widgets.
  final TourTargets? tourTargets;

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
  final _targets = TourTargets();
  final _sosButton = GlobalKey(debugLabel: 'SOS button');

  /// Non-null while the app tour is up.
  AppTourController? _tour;

  void _goTo(AppTab tab) => setState(() => _tab = tab);

  @override
  void initState() {
    super.initState();
    AppTour.replays.addListener(_startTour);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runIntro());
  }

  @override
  void dispose() {
    AppTour.replays.removeListener(_startTour);
    _tour?.dispose();
    super.dispose();
  }

  /// First visit after signing in: "What's new" for people coming from the
  /// old app, then the tour for everyone who hasn't finished it.
  Future<void> _runIntro() async {
    await _routeSettled();
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    var tour = !await IntroPrefs.tourDone();
    if (await IntroPrefs.whatsNewDue()) {
      // Marked first, so it shows once even if the app is closed halfway.
      await IntroPrefs.markWhatsNewSeen();
      if (!mounted) return;
      final choice = await Navigator.of(context).push(WhatsNewScreen.route());
      if (choice == WhatsNewChoice.skipTour) {
        await IntroPrefs.markTourDone();
        tour = false;
      }
    }
    // Something else may have taken over meanwhile, e.g. the update screen.
    if (tour && mounted && (ModalRoute.of(context)?.isCurrent ?? true)) _startTour();
  }

  /// The tour measures real widgets, so wait for the shell's own entrance.
  Future<void> _routeSettled() async {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) return;
    final settled = Completer<void>();
    void listener(AnimationStatus status) {
      if (!status.isAnimating && !settled.isCompleted) settled.complete();
    }

    animation.addStatusListener(listener);
    await settled.future;
    animation.removeStatusListener(listener);
  }

  void _startTour() {
    if (!mounted || _tour != null) return;
    setState(() {
      _tab = AppTab.home;
      _tour = AppTourController()..addListener(_onTour);
    });
  }

  void _onTour() => setState(() {});

  void _endTour() {
    final tour = _tour;
    if (tour == null) return;
    setState(() => _tour = null);
    // The overlay unsubscribes as it unmounts this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => tour.dispose());
    unawaited(IntroPrefs.markTourDone());
  }

  @override
  Widget build(BuildContext context) {
    _built.add(_tab);
    Widget page(AppTab tab, Widget Function() build) =>
        _built.contains(tab) ? build() : const SizedBox.shrink();
    final tour = _tour;

    return ShellScope(
      goTo: _goTo,
      tourTargets: _targets,
      child: PopScope(
        canPop: _tab == AppTab.home && tour == null,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          // Back during the tour works like Skip tour.
          if (tour != null) {
            _endTour();
          } else {
            _goTo(AppTab.home);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // While the tour is up, screen readers only reach its card.
            ExcludeSemantics(
              excluding: tour != null,
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
                bottomNavigationBar: _TabBar(
                  current: _tab,
                  onSelect: _goTo,
                  targets: _targets,
                  sosButton: _sosButton,
                  practice: tour?.practice,
                ),
              ),
            ),
            if (tour != null) AppTourOverlay(controller: tour, targets: _targets, onClose: _endTour),
          ],
        ),
      ),
    );
  }
}

/// The SOS button in the tab bar. While [practice] is set (the app tour's
/// practice step), a completed hold calls only that: [startSos] is never
/// reached, so no countdown, message or location request can start.
class ShellSosButton extends StatelessWidget {
  const ShellSosButton({super.key, this.practice, this.faceKey, this.startSos = startSosFlow});

  final VoidCallback? practice;
  final Key? faceKey;
  final Future<void> Function(BuildContext context) startSos;

  @override
  Widget build(BuildContext context) {
    return SosHoldButton(faceKey: faceKey, onPractice: practice, onTriggered: () => startSos(context));
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onSelect, required this.targets, required this.sosButton, this.practice});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;
  final TourTargets targets;
  final GlobalKey sosButton;
  final VoidCallback? practice;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return _SosReach(
      button: sosButton,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        padding: EdgeInsets.only(top: 8, bottom: bottom > 0 ? bottom : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _item(AppTab.home, Icons.home_outlined, Icons.home_rounded, 'Home'),
            _item(AppTab.learn, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Learn', key: targets.learn),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OverflowBox(
                  maxHeight: 96,
                  alignment: Alignment.bottomCenter,
                  child: ShellSosButton(key: sosButton, faceKey: targets.sos, practice: practice),
                ),
              ),
            ),
            _item(AppTab.safety, Icons.shield_outlined, Icons.shield_rounded, 'Safety', key: targets.safety),
            _item(AppTab.space, Icons.forum_outlined, Icons.forum_rounded, 'Space', key: targets.space),
          ],
        ),
      ),
    );
  }

  Widget _item(AppTab tab, IconData icon, IconData activeIcon, String label, {Key? key}) {
    final selected = tab == current;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      key: key,
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

/// The SOS face rises above the tab bar, and a parent normally only takes
/// touches inside its own bounds. This sends any touch on the face, including
/// the part above the bar, to the button first.
class _SosReach extends SingleChildRenderObjectWidget {
  const _SosReach({required this.button, required super.child});

  final GlobalKey button;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSosReach(button);

  @override
  void updateRenderObject(BuildContext context, _RenderSosReach renderObject) => renderObject.button = button;
}

class _RenderSosReach extends RenderProxyBox {
  _RenderSosReach(this.button);

  GlobalKey button;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final box = button.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached) {
      final toButton = Matrix4.tryInvert(box.getTransformTo(this));
      if (toButton != null &&
          result.addWithRawTransform(
            transform: toButton,
            position: position,
            hitTest: (result, local) => box.hitTest(result, position: local),
          )) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return super.hitTest(result, position: position);
  }
}

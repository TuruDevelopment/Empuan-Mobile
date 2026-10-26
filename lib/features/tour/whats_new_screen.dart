import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';

/// What the person chose on the last page of "What's new".
enum WhatsNewChoice { tour, skipTour }

/// Three pages for people coming from the old app: the new look, the SOS
/// hold, and what changed. Pops with a [WhatsNewChoice]; Skip on the first
/// two pages still leads into the tour.
class WhatsNewScreen extends StatefulWidget {
  const WhatsNewScreen({super.key});

  static Route<WhatsNewChoice> route() => MaterialPageRoute(builder: (_) => const WhatsNewScreen(), fullscreenDialog: true);

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  static const _pages = 3;
  final _controller = PageController();
  int _page = 0;

  bool get _last => _page == _pages - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (EmMotion.reduced(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(page, duration: EmMotion.slow, curve: EmMotion.enter);
    }
  }

  void _close(WhatsNewChoice choice) => Navigator.of(context).pop(choice);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Padding(
                  padding: EdgeInsets.only(left: _page == 0 ? 20 : 8, right: 12),
                  child: Row(
                    children: [
                      if (_page == 0)
                        const EmCaption('What’s new', color: AppColors.primary)
                      else
                        EmIconButton(icon: Icons.arrow_back_ios_new_rounded, label: 'Back', onPressed: () => _goTo(_page - 1)),
                      const Spacer(),
                      if (!_last)
                        EmButton(
                          label: 'Skip',
                          variant: EmButtonVariant.text,
                          small: true,
                          expand: false,
                          onPressed: () => _close(WhatsNewChoice.tour),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: const [_NewLookPage(), _HoldSosPage(), _ChangesPage()],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Dots(page: _page, count: _pages),
                    const SizedBox(height: 16),
                    EmStateSwitcher(
                      stateKey: _last,
                      child: _last
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                EmButton(label: 'Show me around', onPressed: () => _close(WhatsNewChoice.tour)),
                                const SizedBox(height: 8),
                                EmButton(label: 'Skip the tour', variant: EmButtonVariant.text, onPressed: () => _close(WhatsNewChoice.skipTour)),
                              ],
                            )
                          : EmButton(label: 'Next', onPressed: () => _goTo(_page + 1)),
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

class _Dots extends StatelessWidget {
  const _Dots({required this.page, required this.count});

  final int page;
  final int count;

  @override
  Widget build(BuildContext context) {
    final duration = EmMotion.reduced(context) ? Duration.zero : EmMotion.medium;
    return Semantics(
      label: 'Page ${page + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: duration,
              curve: EmMotion.enter,
              width: i == page ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == page ? AppColors.primary : AppColors.line2,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Page layout: a blush illustration panel, then the heading and text.
/// Scrolls when large text or a short screen doesn't leave room.
class _ArtPage extends StatelessWidget {
  const _ArtPage({required this.art, required this.title, required this.body});

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: (constraints.maxHeight * 0.55).clamp(150.0, 330.0),
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(28)),
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: Padding(padding: const EdgeInsets.all(16), child: FittedBox(fit: BoxFit.scaleDown, child: art)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(title, style: text.headlineLarge)),
                  const SizedBox(height: 12),
                  Text(body, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewLookPage extends StatelessWidget {
  const _NewLookPage();

  @override
  Widget build(BuildContext context) {
    return const _ArtPage(
      art: _MiniTabBar(),
      title: 'Empuan has a new look',
      body:
          'Everything now lives in five places: Home, Learn, Safety, Her Space, and the SOS button in the middle. Your profile is behind your initials on Home.',
    );
  }
}

/// A small copy of the real tab bar, with Home selected.
class _MiniTabBar extends StatelessWidget {
  const _MiniTabBar();

  @override
  Widget build(BuildContext context) {
    Widget tab(IconData icon, String label, {bool on = false}) {
      final color = on ? AppColors.primary : AppColors.textSecondary;
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
    }

    return Padding(
      // Room for the raised SOS button.
      padding: const EdgeInsets.only(top: 20),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 300,
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: Color(0x244B0E28), blurRadius: 30, offset: Offset(0, 10))],
            ),
            child: Row(
              children: [
                tab(Icons.home_rounded, 'Home', on: true),
                tab(Icons.menu_book_outlined, 'Learn'),
                const Spacer(),
                tab(Icons.shield_outlined, 'Safety'),
                tab(Icons.forum_outlined, 'Space'),
              ],
            ),
          ),
          Positioned(
            top: -20,
            child: Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 4),
              ),
              child: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldSosPage extends StatelessWidget {
  const _HoldSosPage();

  @override
  Widget build(BuildContext context) {
    return const _ArtPage(
      art: _HoldRing(),
      title: 'SOS now works with one hold',
      body:
          'Press and hold SOS for 3 seconds. Your messages app opens with a help text and your location, ready to send to your trusted contacts. A quick tap does nothing, so it won’t go off in your pocket.',
    );
  }
}

/// The SOS button mid-hold. The ring fills once when the page first shows.
class _HoldRing extends StatelessWidget {
  const _HoldRing();

  @override
  Widget build(BuildContext context) {
    const fill = 0.68;
    final reduced = EmMotion.reduced(context);
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduced ? fill : 0, end: fill),
            duration: const Duration(milliseconds: 1400),
            curve: EmMotion.enter,
            builder: (_, value, __) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 14,
                strokeCap: StrokeCap.butt,
                color: AppColors.danger,
                backgroundColor: const Color(0xFFF3C5CE),
              ),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blush, width: 6),
            ),
            child: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: 1.7)),
          ),
        ],
      ),
    );
  }
}

class _ChangesPage extends StatelessWidget {
  const _ChangesPage();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(IconData icon, String title, String body, {bool removed = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: removed ? AppColors.line : AppColors.blush, borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, size: 18, color: removed ? AppColors.textSecondary : AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(body, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text('What’s changed', style: text.headlineLarge)),
          const SizedBox(height: 20),
          row(Icons.menu_book_outlined, 'Learn', 'Short courses on career, money, safety and digital skills, with certificates.'),
          row(Icons.auto_awesome_outlined, 'Empuan AI', 'Ask private questions and get answers with links to courses, articles and safety tools.'),
          row(Icons.flag_outlined, 'Report and block in Her Space', 'Report a post, reply or AI answer, and block anyone you don’t want to see.'),
          row(
            Icons.delete_outline_rounded,
            'Period tracker and wellness check-ins removed',
            'Empuan now focuses on safety, learning and community.',
            removed: true,
          ),
        ],
      ),
    );
  }
}

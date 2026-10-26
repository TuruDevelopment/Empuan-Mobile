import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';
import 'login_screen.dart';
import 'welcome_art.dart';
import 'signup_flow.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.sessionExpired = false});

  final bool sessionExpired;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  int _index = 0;

  /// In the order of [WelcomeArt.slide].
  static const _slides = [
    (
      title: 'Look after yourself, with backup',
      body: 'Learn practical skills, talk with other women, and reach the people you trust with one hold of a button.',
    ),
    (
      title: 'Learn at your own pace',
      body: 'Short courses on money, work and staying safe, made for women in Indonesia.',
    ),
    (
      title: 'Help is one hold away',
      body: 'Hold SOS for 3 seconds and your trusted contacts get a text with your location.',
    ),
    (
      title: 'Ask anything, any time',
      body: 'Empuan AI answers questions about safety, work and money, and points you to the right course or help line.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showEmToast(context, 'Your session has ended. Please log in again.', icon: Icons.lock_clock_outlined);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  double _offsetOf(int i) {
    if (!_pages.hasClients) return 0;
    final page = _pages.page;
    return page == null ? 0 : page - i;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reduced = EmMotion.reduced(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(alignment: Alignment.centerLeft, child: EmWordmark()),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return LayoutBuilder(
                    builder: (context, c) {
                      // Takes whatever height the text leaves, up to its full size,
                      // so small phones get a smaller picture instead of overflowing.
                      final illustration = ConstrainedBox(constraints: const BoxConstraints(maxHeight: 330), child: WelcomeArt(i));
                      final title = Text(s.title, textAlign: TextAlign.center, style: text.headlineLarge);
                      final body = Text(s.body, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary));
                      return AnimatedBuilder(
                        animation: _pages,
                        builder: (context, _) {
                          // How far this slide is from the centre, -1..1, while swiping.
                          final t = reduced ? 0.0 : _offsetOf(i).clamp(-1.0, 1.0);
                          // Text fades out quickly so neighbouring slides cross-fade
                          // rather than sliding over each other.
                          final textOpacity = (1 - t.abs() * 1.6).clamp(0.0, 1.0);
                          // Scrolls only when even the text doesn't fit, e.g. landscape
                          // or very large text.
                          return CustomScrollView(
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 28),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Illustration lags behind the page (parallax) and shrinks a touch.
                                      Flexible(
                                        child: Transform.translate(
                                          offset: Offset(t * c.maxWidth * 0.35, 0),
                                          child: Transform.scale(scale: 1 - 0.12 * t.abs(), child: illustration),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Opacity(opacity: textOpacity, child: title),
                                      const SizedBox(height: 12),
                                      Opacity(opacity: textOpacity, child: body),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Semantics(
              label: 'Slide ${_index + 1} of ${_slides.length}',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: reduced ? Duration.zero : EmMotion.medium,
                      curve: EmMotion.enter,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.primary : AppColors.line2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                children: [
                  EmFadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: EmButton(label: 'Create account', onPressed: () => pushScreen(context, const SignupFlow())),
                  ),
                  const SizedBox(height: 12),
                  EmFadeSlideIn(
                    index: 1,
                    delay: const Duration(milliseconds: 120),
                    child: EmButton(
                      label: 'I already have an account',
                      variant: EmButtonVariant.secondary,
                      onPressed: () => pushScreen(context, const LoginScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

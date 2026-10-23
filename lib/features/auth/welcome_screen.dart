import 'package:flutter/material.dart';

import '../../ui/em_ui.dart';
import 'login_screen.dart';
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

  static const _slides = [
    (
      image: 'images/intro2.png',
      title: 'Look after yourself, with backup',
      body: 'Learn practical skills, talk with other women, and reach the people you trust with one hold of a button.',
    ),
    (
      image: 'images/intro1.png',
      title: 'Learn at your own pace',
      body: 'Short courses on money, work and staying safe, made for women in Indonesia.',
    ),
    (
      image: 'images/intro3.png',
      title: 'Help is one hold away',
      body: 'Hold SOS for 3 seconds and your trusted contacts get a text with your location.',
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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                      final art = (c.maxHeight * 0.48).clamp(160.0, 300.0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: art,
                              height: art,
                              decoration: const BoxDecoration(color: AppColors.blush, shape: BoxShape.circle),
                              padding: EdgeInsets.all(art * 0.12),
                              child: Image.asset(s.image, fit: BoxFit.contain, excludeFromSemantics: true),
                            ),
                            const SizedBox(height: 28),
                            Text(s.title, textAlign: TextAlign.center, style: text.headlineLarge),
                            const SizedBox(height: 12),
                            Text(s.body, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
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
                      duration: const Duration(milliseconds: 200),
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
                  EmButton(label: 'Create account', onPressed: () => pushScreen(context, const SignupFlow())),
                  const SizedBox(height: 12),
                  EmButton(
                    label: 'I already have an account',
                    variant: EmButtonVariant.secondary,
                    onPressed: () => pushScreen(context, const LoginScreen()),
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

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
// import 'package:Empuan/signUpPage.dart';
import 'package:Empuan/start_page.dart';
import 'package:Empuan/styles/style.dart';
import 'package:Empuan/tempSignUpPage.dart';

class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> with TickerProviderStateMixin {
  late PageController _pageViewController = PageController();
  late TabController _tabController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.accent.withOpacity(0.15),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              bottom: 180,
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageViewController,
                onPageChanged: _handlePageViewChanged,
                children: [
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'images/intro1.png',
                                width: 250,
                                height: 250,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 250,
                                    height: 250,
                                    color: AppColors.accent.withOpacity(0.3),
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 80,
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'Breaking Stereotypes,\nEmpowering Women',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 26,
                              height: 1.3,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Empuan App Paves the Way for\nGender Equality in Indonesia',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: 40), // Extra space untuk indicator
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'images/intro2.png',
                                width: 250,
                                height: 250,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 250,
                                    height: 250,
                                    color: AppColors.accent.withOpacity(0.3),
                                    child: Icon(
                                      Icons.people_outline,
                                      size: 80,
                                      color: AppColors.secondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'Safe Spaces, Collective Growth',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 26,
                              height: 1.3,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Empuan App Fosters Women\'s\nEmpowerment and Equality',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: 40), // Extra space untuk indicator
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'images/intro3.png',
                                width: 250,
                                height: 250,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 250,
                                    height: 250,
                                    color: AppColors.accent.withOpacity(0.3),
                                    child: Icon(
                                      Icons.campaign_outlined,
                                      size: 80,
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'For Awareness to Action',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 26,
                              height: 1.3,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Empuan App Bridges Gaps, Advocates for\nWomen\'s Rights and Well-being.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: 40), // Extra space untuk indicator
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: PageIndicator(
                tabController: _tabController,
                currentPageIndex: _currentPageIndex,
                onUpdateCurrentPageIndex: _updateCurrentPageIndex,
                // isOnDesktopAndWeb: _isOnDesktopAndWeb,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    _tabController.index = currentPageIndex;
    setState(() {
      _currentPageIndex = currentPageIndex;
    });
  }

  void _updateCurrentPageIndex(int index) {
    _tabController.index = index;
    _pageViewController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }
}

class PageIndicator extends StatelessWidget {
  PageIndicator({
    super.key,
    required this.tabController,
    required this.currentPageIndex,
    required this.onUpdateCurrentPageIndex,
  });

  final int currentPageIndex;
  final TabController tabController;
  final void Function(int) onUpdateCurrentPageIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          // Page Indicators
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TabPageSelector(
                  controller: tabController,
                  color: AppColors.accent,
                  selectedColor: AppColors.primary,
                  borderStyle: BorderStyle.solid,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Back/Cancel Button
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Container(
                  width: 120,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: OutlinedButton(
                    onPressed: () {
                      if (currentPageIndex == 0) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const StartPage(),
                          ),
                        );
                        return;
                      }
                      onUpdateCurrentPageIndex(currentPageIndex - 1);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      currentPageIndex == 0 ? 'Cancel' : 'Back',
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              // Next/Start Button
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Container(
                  width: 120,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryVariant,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (currentPageIndex == 2) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const tempSignUpPage(),
                          ),
                        );
                        return;
                      }
                      onUpdateCurrentPageIndex(currentPageIndex + 1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      currentPageIndex == 2 ? 'Let\'s Start' : 'Next',
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

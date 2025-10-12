import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:tumpuan/signUpPage.dart';
import 'package:tumpuan/start_page.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:tumpuan/tempSignUpPage.dart';

class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> with TickerProviderStateMixin{
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
      body: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          bottom: 100,
          child: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageViewController,
          onPageChanged: _handlePageViewChanged,
          children: [
            Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Image(image: AssetImage('images/intro1.png')),
            const SizedBox(height: 15),
            const Text(
              'Breaking Stereotypes,\nEmpowering Women',
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.bold,
                  color: AppColors.pink1,
                  fontSize: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tumpuan App Paves the Way for\nGender Equality in Indonesia',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
            ),
            Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Image(image: AssetImage('images/intro2.png')),
            const SizedBox(height: 15),
            const Text(
              'Safe Spaces, Collective Growth',
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.bold,
                  color: AppColors.pink1,
                  fontSize: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tumpuan App Fosters Women\'s\nEmpowerment and Equality',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
            ),
            Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Image(image: AssetImage('images/intro3.png')),
            const SizedBox(height: 15),
            const Text(
              'For Awareness to Action',
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.bold,
                  color: AppColors.pink1,
                  fontSize: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tumpuan App Bridges Gaps, Advocates for\nWomen\'s Rights and Well-being.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
            ),
          ],
        ),
        ),
        Positioned(
          bottom: 150,
          child: PageIndicator(
          tabController: _tabController,
          currentPageIndex: _currentPageIndex,
          onUpdateCurrentPageIndex: _updateCurrentPageIndex,
          // isOnDesktopAndWeb: _isOnDesktopAndWeb,
          ),
        )
      ],
    )
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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children:[
        Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TabPageSelector(
            controller: tabController,
            color: Colors.white,
            selectedColor: AppColors.pink1,
          ),
        ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
            padding: const EdgeInsets.only(right: 7.0),
            child: Visibility(
              child: SizedBox(
                width: 109,
                child: FilledButton(
                  onPressed: () {
                    if (currentPageIndex == 0) {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const StartPage()));
                    return;
                   }
                   onUpdateCurrentPageIndex(currentPageIndex - 1);
                  },
                  style: ButtonStyle(
                       backgroundColor: MaterialStateProperty.all(
                      const Color.fromRGBO(251, 111, 146, 1))),
                  child: Text(
                  currentPageIndex == 0 ? 'Cancel' : 'Back',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    ),
                ),
                ),
            ),
            )
        ),
        Padding(
            padding: const EdgeInsets.only(right: 7.0),
            child: SizedBox(
                width: 109,
                child: FilledButton(
                  onPressed: () {
                   if (currentPageIndex == 2) {
                    Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const tempSignUpPage()));
                    return;
                  }
                  onUpdateCurrentPageIndex(currentPageIndex + 1);
                  },
                  style: ButtonStyle(
                       backgroundColor: MaterialStateProperty.all(
                      const Color.fromRGBO(251, 111, 146, 1))),
                  child: Text(
                  currentPageIndex == 2 ? 'Let\'s Start' : 'Next',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    ),
                ),
                ),
            ),
        ),
        ],
        ),
        ]
      )
      // child: Row(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: <Widget>[
      //     IconButton(
      //       splashRadius: 16.0,
      //       padding: EdgeInsets.zero,
      //       onPressed: () {
      //         if (currentPageIndex == 0) {
      //           return;
      //         }
      //         onUpdateCurrentPageIndex(currentPageIndex - 1);
      //       },
      //       icon: const Icon(
      //         Icons.arrow_left_rounded,
      //         size: 32.0,
      //       ),
      //     ),
      //     TabPageSelector(
      //       controller: tabController,
      //       color: Colors.white,
      //       selectedColor: AppColors.pink1,
      //     ),
      //     IconButton(
      //       splashRadius: 16.0,
      //       padding: EdgeInsets.zero,
      //       onPressed: () {
      //         if (currentPageIndex == 2) {
      //           return;
      //         }
      //         onUpdateCurrentPageIndex(currentPageIndex + 1);
      //       },
      //       icon: const Icon(
      //         Icons.arrow_right_rounded,
      //         size: 32.0,
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}


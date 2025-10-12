import 'package:flutter/material.dart';
import '../Widgets/sliver_app_bar.dart';
import '../Widgets/sliver_list.dart';
import '../Widgets/sliver_list2.dart';
import '../Widgets/sliver_list3.dart';
import '../Widgets/sliver_search.dart';
import '../screensUntukPuan/foodPage.dart';
import '../screensUntukPuan/saloonPage.dart';
import '../screensUntukPuan/spaPage.dart';

class UntukPuan extends StatefulWidget {
  const UntukPuan({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _UntukPuanState createState() => _UntukPuanState();
}

class _UntukPuanState extends State<UntukPuan> {
  final PageController controller = PageController();
  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 280,
            child: CustomScrollView(
              slivers: [
                SliverAppBarBldr(),
                SliverAppBar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  pinned: true,
                  bottom: const PreferredSize(
                      preferredSize: Size.fromHeight(-30.0), child: SizedBox()),
                  flexibleSpace: NavBar(
                    onTabChanged: (index) {
                      controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    currentTab: currentTab,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: controller,
              onPageChanged: (index) {
                setState(() {
                  currentTab = index;
                });
              },
              children: [
                CustomScrollView(
                  slivers: [
                    // SliverListBldr(),
                    // Add other slivers as needed
                  ],
                ),
                CustomScrollView(
                  slivers: [
                    SliverListBldr2(),

                    // Add other slivers as needed
                  ],
                ),
                CustomScrollView(
                  slivers: [
                    SliverListBldr3(),
                    // Add other slivers as needed
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavBar extends StatelessWidget {
  const NavBar({Key? key, required this.onTabChanged, required this.currentTab})
      : super(key: key);

  final void Function(int) onTabChanged;
  final int currentTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTab('Spa & Massage', 0),
        _buildTab('Saloon', 1),
        _buildTab('Food', 2),
      ],
    );
  }

  Widget _buildTab(String text, int index) {
    return MaterialButton(
      minWidth: 40,
      onPressed: () => onTabChanged(index),
      child: Text(
        text,
        style: TextStyle(
          color: currentTab == index
              ? const Color.fromRGBO(251, 111, 146, 1)
              : Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }
}

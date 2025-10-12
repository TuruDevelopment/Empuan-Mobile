import 'package:flutter/material.dart';
import 'package:tumpuan/screensUntukPuan/foodPage.dart';
import 'package:tumpuan/screensUntukPuan/saloonPage.dart';
import 'package:tumpuan/screensUntukPuan/spaPage.dart';

class SliverSearch extends StatelessWidget {
  const SliverSearch({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      pinned: true,
      bottom: const PreferredSize(
          preferredSize: Size.fromHeight(-30.0), child: SizedBox()),
      flexibleSpace: NavBar(),
    );
  }

  // @override
  // State<StatefulWidget> createState() {
  //   // TODO: implement createState
  //   throw UnimplementedError();
  // }
}

class NavBar extends StatefulWidget {
  const NavBar({Key? key}) : super(key: key);
  @override
  State<NavBar> createState() => _NavBar();

  // @override
  // State<StatefulWidget> createState() {
  //   // TODO: implement createState
  //   throw UnimplementedError();
  // }
}

class _NavBar extends State<NavBar> {
  int currentTab = 0;
  final List<Widget> screens = [
    const SpaPage(),
    const SaloonPage(),
    const FoodPage(),
  ];

  final PageStorageBucket bucket = PageStorageBucket();
  Widget currentScreen = const SpaPage();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // PageStorage(bucket: bucket, child: currentScreen),
        MaterialButton(
            minWidth: 40,
            onPressed: () {
              setState(() {
                currentScreen = const SpaPage();
                currentTab = 0;
              });
            },
            child: Text(
              'Spa & Massage',
              style: TextStyle(
                  color: currentTab == 0
                      ? const Color.fromRGBO(251, 111, 146, 1)
                      : Colors.grey,
                  fontSize: 12),
            )),
        MaterialButton(
            minWidth: 40,
            onPressed: () {
              setState(() {
                currentScreen = const SaloonPage();
                currentTab = 1;
              });
            },
            child: Text(
              'Saloon',
              style: TextStyle(
                  color: currentTab == 1
                      ? const Color.fromRGBO(251, 111, 146, 1)
                      : Colors.grey,
                  fontSize: 12),
            )),
        MaterialButton(
            minWidth: 40,
            onPressed: () {
              setState(() {
                currentScreen = const FoodPage();
                currentTab = 2;
              });
            },
            child: Text(
              'Food',
              style: TextStyle(
                  color: currentTab == 2
                      ? const Color.fromRGBO(251, 111, 146, 1)
                      : Colors.grey,
                  fontSize: 12),
            )),
        // TextButton(onPressed: () {}, child: Text('Spa & Massage')),
        // TextButton(onPressed: () {}, child: Text('Saloon')),
        // TextButton(onPressed: () {}, child: Text('Food'))
      ],
    );
  }
}

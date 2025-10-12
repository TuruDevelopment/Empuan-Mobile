import 'package:flutter/material.dart';
import 'package:tumpuan/screensUntukPuan/foodPage.dart';
import 'package:tumpuan/screensUntukPuan/saloonPage.dart';
import 'package:tumpuan/screensUntukPuan/spaPage.dart';

class PageViewUP extends StatelessWidget {
  const PageViewUP({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavBar();
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

  PageController controller = PageController();
  final List<Widget> _list = <Widget>[
    Center(
        child: Pages(
      text: "Page One",
      color: Colors.teal,
    )),
    Center(
        child: Pages(
      text: "Page Two",
      color: Colors.red.shade100,
    )),
    Center(
        child: Pages(
      text: "Page Three",
      color: Colors.grey,
    )),
    Center(
        child: Pages(
      text: "Page Four",
      color: Colors.yellow.shade100,
    ))
  ];
  int _curr = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliverAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          pinned: true,
          bottom: const PreferredSize(
              preferredSize: Size.fromHeight(-30.0), child: SizedBox()),
          // flexibleSpace: NavBar(),
        ),
        Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('PageView'),
            backgroundColor: Colors.lightBlueAccent,
          ),
          body: PageView(
            allowImplicitScrolling: true,
            children: _list,
            scrollDirection: Axis.vertical,
            // reverse: true,
            // physics: BouncingScrollPhysics(),
            controller: controller,
            onPageChanged: (num) {
              setState(() {
                _curr = num;
              });
            },
          ),
        ),
      ],
    );
  }
}

class Pages extends StatelessWidget {
  final text;
  final color;
  Pages({this.text, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                text,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
              ),
            ]),
      ),
    );
  }
}

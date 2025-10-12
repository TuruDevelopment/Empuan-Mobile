// import 'package:flutter/material.dart';
// import 'package:tumpuan/screens/catatanHaid.dart';
// import 'package:tumpuan/screens/HomePage.dart';
// import 'package:tumpuan/screens/more.dart';
// import 'package:tumpuan/screens/pageHome.dart';
// import 'package:tumpuan/screens/panggilPuan.dart';
// import 'package:tumpuan/screens/tombolAman.dart';
// import 'package:tumpuan/screens/suaraPuan.dart';

// class Home extends StatefulWidget {
//   const Home({Key? key}) : super(key: key);

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   // Widget currentScreen = HomePage();
//   int currentTab = 0;
//   bool sosActive = false;
//   Gradient _gradient = LinearGradient(colors: [
//     const Color.fromRGBO(251, 111, 146, 1),
//     const Color.fromRGBO(255, 143, 171, 1)
//   ]);

//   Gradient _gradient2 = LinearGradient(colors: [
//     Color.fromARGB(255, 37, 159, 70),
//     Color.fromARGB(255, 37, 159, 70)
//   ]);

//   Icon icon1 = Icon(
//     Icons.sos,
//     size: 30,
//     color: Colors.white,
//   );
//   Icon icon2 = Icon(
//     Icons.close,
//     size: 30,
//     color: Colors.white,
//   );

//   final List<Widget> screens = [
//     // HomePage(),
//     PageHome(),
//     // CatatanHaid(),
//     PanggilPuan(),
//     TombolAman(),
//     More()
//   ];

//   final PageStorageBucket bucket = PageStorageBucket();

//   @override
//   Widget build(BuildContext context) {
//     Widget okButton = TextButton(
//       child: Text(
//         "OK",
//         style: TextStyle(
//             color: const Color.fromRGBO(251, 111, 146, 1),
//             fontFamily: 'Satoshi'),
//       ),
//       onPressed: () {
//         Navigator.of(context).pop();
//       },
//     );

//     // set up the AlertDialog
//     AlertDialog alert = AlertDialog(
//       // title: Text("My title"),
//       content: Text(
//         "Your Location is Now Shared to Your Contacts",
//         style: TextStyle(
//             fontFamily: 'Satoshi', fontWeight: FontWeight.bold, fontSize: 15),
//       ),
//       actions: [
//         // okButton,
//       ],
//       // backgroundColor: Colors.transparent,
//       insetPadding: EdgeInsets.only(top: 470, left: 80, right: 80),
//       shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.all(Radius.circular(32.0))),
//     );
//     return WillPopScope(
//       onWillPop: () async {
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
//         body: PageStorage(
//           bucket: bucket,
//           child: currentScreen,
//         ),
//         floatingActionButton: FloatingActionButton(
//           child: Container(
//               width: 60,
//               height: 60,
//               decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: sosActive ? _gradient2 : _gradient),
//               child: sosActive ? icon2 : icon1),
//           onPressed: () {
//             setState(() {
//               sosActive = !sosActive;
//               if (sosActive) {
//                 showDialog(
//                     barrierColor: Color(0x01000000),
//                     context: context,
//                     builder: (BuildContext context) {
//                       Future.delayed(Duration(seconds: 3), () {
//                         Navigator.of(context).pop(true);
//                       });
//                       return alert;
//                     });
//               }
//             });
//           },
//         ),
//         floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//         bottomNavigationBar: BottomAppBar(
//           color: const Color.fromRGBO(237, 237, 237, 1),
//           shape: const CircularNotchedRectangle(),
//           notchMargin: 10,
//           child: SizedBox(
//             height: 60,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: <Widget>[
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     MaterialButton(
//                       minWidth: 40,
//                       onPressed: () {
//                         // setState(() {
//                         //   currentScreen = HomePage();
//                         //   currentTab = 0;
//                         // });
//                       },
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.home,
//                             color: currentTab == 0
//                                 ? const Color.fromRGBO(251, 111, 146, 1)
//                                 : Colors.grey,
//                           ),
//                           Text(
//                             'Home',
//                             style: TextStyle(
//                                 color: currentTab == 0
//                                     ? const Color.fromRGBO(251, 111, 146, 1)
//                                     : Colors.grey,
//                                 fontSize: 12),
//                           )
//                         ],
//                       ),
//                     ),
//                     MaterialButton(
//                       minWidth: 40,
//                       onPressed: () {
//                         // setState(() {
//                         //   currentScreen =
//                         //   CatatanHaid(

//                         //   );
//                         //   currentTab = 1;
//                         // });
//                       },
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.calendar_month,
//                             color: currentTab == 1
//                                 ? const Color.fromRGBO(251, 111, 146, 1)
//                                 : Colors.grey,
//                           ),
//                           Text(
//                             'Catatan Haid',
//                             style: TextStyle(
//                                 color: currentTab == 1
//                                     ? const Color.fromRGBO(251, 111, 146, 1)
//                                     : Colors.grey,
//                                 fontSize: 12),
//                           )
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     MaterialButton(
//                       minWidth: 40,
//                       onPressed: () {
//                         setState(() {
//                           currentScreen = PanggilPuan();
//                           currentTab = 3;
//                         });
//                       },
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.call,
//                             color: currentTab == 3
//                                 ? const Color.fromRGBO(251, 111, 146, 1)
//                                 : Colors.grey,
//                           ),
//                           Text(
//                             'Panggil Puan',
//                             style: TextStyle(
//                                 color: currentTab == 3
//                                     ? const Color.fromRGBO(251, 111, 146, 1)
//                                     : Colors.grey,
//                                 fontSize: 12),
//                           )
//                         ],
//                       ),
//                     ),
//                     MaterialButton(
//                       minWidth: 40,
//                       onPressed: () {
//                         setState(() {
//                           currentScreen = More();
//                           currentTab = 4;
//                         });
//                       },
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.more_horiz,
//                             color: currentTab == 4
//                                 ? const Color.fromRGBO(251, 111, 146, 1)
//                                 : Colors.grey,
//                           ),
//                           Text(
//                             'More',
//                             style: TextStyle(
//                                 color: currentTab == 4
//                                     ? const Color.fromRGBO(251, 111, 146, 1)
//                                     : Colors.grey,
//                                 fontSize: 12),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

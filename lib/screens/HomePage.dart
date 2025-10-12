import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tumpuan/components/dailyQuiz.dart';
import 'package:tumpuan/components/widgetUntukPuan.dart';
import 'package:tumpuan/screens/catatanHaid.dart';
import 'package:tumpuan/screens/newUntukPuan.dart';
import 'package:tumpuan/screens/suaraPuan.dart';
import 'package:tumpuan/screens/untukPuan.dart';
import 'package:tumpuan/screens/home.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.startdate, required this.enddate});

  final DateTime startdate;
  final DateTime enddate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;

  void initState() {
    super.initState();
    getCurrentUser().then((userid) {
      if (userid != null) {
        getData(userid);
      }
    });
  }

  late int countdown = 22;
  late DateTime _rangeStartDay = widget.startdate;
  late DateTime _rangeEndDay = widget.enddate;
  late DateTime _rangeStartDayplus30 =
      _rangeStartDay.add(const Duration(days: 30));
  late DateTime _rangeEndDayplus30 = _rangeEndDay.add(const Duration(days: 30));

  // late DateTime _startdate = DateTime.now();
  // late DateTime _enddate = DateTime.now();

  Future<String?> getCurrentUser() async {
    final url = 'http://10.0.2.2:8000/api/users/current';
    final uri = Uri.parse(url);

    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['data'] != null) {
        final data = jsonData['data'];
        if (data.containsKey('id')) {
          return data['id'].toString();
        }
      }
    }
    return null;
  }

  Future<void> getData(String userid) async {
    setState(() {
      isLoading = true;
    });

    final url = 'http://10.0.2.2:8000/api/catatanhaids/$userid';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['data'] != null) {
        final data = jsonData['data'];

        if (data['start_date'] != null && data['end_date'] != null) {
          setState(() {
            _rangeStartDay = DateTime.parse(data['start_date']);
            _rangeEndDay = DateTime.parse(data['end_date']);
          });
        }
      }
    }

    setState(() {
      isLoading = false;
    });

    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }

  @override
  Widget build(BuildContext context) {
    _rangeStartDayplus30 = _rangeStartDay.add(const Duration(days: 30));
    _rangeEndDayplus30 = _rangeEndDay.add(const Duration(days: 30));
    print("nbb start date $_rangeStartDay");
    print("uhu end date $_rangeEndDay");
    Duration difference = _rangeStartDayplus30.difference(DateTime.now());
    countdown = difference.inDays;
    // print(_startdate + '-' + _enddate);

    String formattedEndDate =
        DateFormat('d MMMM yyyy').format(_rangeEndDayplus30);
    String formattedStartDate =
        DateFormat('d MMMM yyyy').format(_rangeStartDayplus30);

    // NavBar newNav = new NavBar();

    String prediction =
        'Prediction : ' + formattedStartDate + ' - ' + formattedEndDate;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Tumpuan',
            style: TextStyle(
                fontFamily: 'Brodies', color: Color.fromRGBO(251, 111, 146, 1)),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.grey,
            ),
            onPressed: () {},
          )
        ],
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 300,
            // color: Colors.amber,
            child: SingleChildScrollView(
              child: Column(
                // mainAxisAlignment: Ma,
                children: [
                  // SizedBox(height: 15),
                  Container(
                    width: 600,
                    height: 200,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("images/BannerSuaraPuan.png"))),
                  ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceAro,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const SuaraPuan(
                                  // title: 'Suara Puan',
                                  )));
                          // ScreenChanger.changeScreen(SuaraPuan(), 0, () {
                          //   setState(() {});
                          // });
                        },
                        child: Container(
                          width: 145,
                          height: 80,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image:
                                      AssetImage("images/btn_suarapuan.png"))),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const newUntukPuan(
                                  // title: 'Untuk Puan',
                                  )));
                        },
                        child: Container(
                          width: 145,
                          height: 80,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image:
                                      AssetImage("images/btn_untukpuan.png"))),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceAro,
                    children: [
                      Stack(children: [
                        Container(
                          width: 145,
                          height: 150,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image:
                                      AssetImage("images/btn_countdown.png"))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 23, vertical: 35),
                          child: Text(
                            '${countdown} Days',
                            style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color:
                                    const Color.fromARGB(255, 255, 255, 255)),
                          ),
                        )
                      ]),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                  builder: (context) => const DailyQuiz()));
                        },
                        child: Container(
                          width: 145,
                          height: 150,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image:
                                      AssetImage("images/btn_dailyquiz.png"))),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Divider(
                    color: Colors.black,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Your Period Tracker',
                    style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset('images/homeCircle.png'),
                      Image.asset('images/homeElipse.png'),
                      Column(
                        children: [
                          Text(
                            'Period in',
                            style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 10,
                                fontWeight: FontWeight.w200),
                          ),
                          Text(
                            '${countdown} Days',
                            style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pink1),
                          )
                        ],
                      )
                    ],
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    prediction,
                    style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        fontWeight: FontWeight.w100,
                        color: Colors.black),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    height: 25,
                    child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(AppColors.pink1)),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CatatanHaid(
                                  startdate: widget.startdate,
                                  enddate: widget.enddate,
                                )));
                      },
                      child: Text(
                        'See Details',
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 10,
                            fontWeight: FontWeight.w400),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

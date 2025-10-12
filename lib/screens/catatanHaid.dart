import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;

class CatatanHaid extends StatefulWidget {
  const CatatanHaid({Key? key, required this.startdate, required this.enddate})
      : super(key: key);

  final DateTime startdate;
  final DateTime enddate;

  @override
  State<CatatanHaid> createState() => _CatatanHaidState();
}

class _CatatanHaidState extends State<CatatanHaid> {
  bool isLoading = true;

  void initState() {
    super.initState();
    getCurrentUser().then((userid) {
      if (userid != null) {
        getData(userid);
      }
    });
  }

  late DateTime _focusedDay = DateTime.now();
  late DateTime _selectedDay = DateTime.now();
  // late DateTime _rangeStartDay =
  //     DateTime.utc(2024, 2, 26); // start period dari database
  late DateTime _rangeStartDay = widget.startdate;
  late DateTime _rangeStartDayplus30 =
      _rangeStartDay.add(const Duration(days: 30));
  late DateTime _rangeStartDayminus30 =
      _rangeStartDay.subtract(const Duration(days: 30));

  // late DateTime _rangeEndDay =
  //     DateTime.utc(2024, 3, 3); // end period dari database
  late DateTime _rangeEndDay = widget.enddate;
  late DateTime _rangeEndDayplus30 = _rangeEndDay.add(const Duration(days: 30));
  late DateTime _rangeEndDayminus30 =
      _rangeEndDay.subtract(const Duration(days: 30));
  late DateTime _previousFocusedMonth = DateTime.now();

  late int startCycle = 28;
  late int endCycle = 34;

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
    _rangeStartDayminus30 = _rangeStartDay.subtract(const Duration(days: 30));
    _rangeEndDayplus30 = _rangeEndDay.add(const Duration(days: 30));
    _rangeEndDayminus30 = _rangeEndDay.subtract(const Duration(days: 30));
    print("start date $_rangeStartDay");
    print("end date $_rangeEndDay");
    print("start date plus$_rangeStartDayplus30");
    print("end date plus $_rangeEndDayplus30");
    print("start date minus$_rangeStartDayminus30");
    print("end date minus $_rangeEndDayminus30");
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
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Text('data'),
                TableCalendar(
                  // rangeStartDay: _rangeStartDay,
                  // rangeEndDay: _rangeEndDay,
                  // rangeSelectionMode: RangeSelectionMode.toggledOn,
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  // firstDay: _rangeStartDay,
                  // lastDay: _rangeEndDay,
                  focusedDay: _focusedDay,
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                      _handlePageChange();
                    });
                  },
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'month'
                  },
                  calendarStyle: const CalendarStyle(
                    defaultTextStyle: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                    ),
                    weekendTextStyle: TextStyle(
                      color: Colors.red,
                    ),
                    // selectedDecoration: BoxDecoration(
                    //   color: Colors.blueAccent,
                    //   shape: BoxShape.circle,
                    // ),
                    // rangeHighlightColor: AppColors
                    //     .pink1, // Ubah warna range seleksi menjadi pink
                    // rangeStartDecoration: BoxDecoration(
                    //   color: AppColors.pink1,
                    //   shape: BoxShape.circle,
                    // ),
                    // rangeEndDecoration: BoxDecoration(
                    //   color: AppColors.pink1,
                    //   shape: BoxShape.circle,
                    // ),
                    // withinRangeTextStyle: TextStyle(
                    //     fontFamily: 'Satoshi',
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.white),
                    // rangeStartTextStyle: TextStyle(
                    //     fontFamily: 'Satoshi',
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.white),
                    // rangeEndTextStyle: TextStyle(
                    //     fontFamily: 'Satoshi',
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.white),
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: HeaderStyle(
                    titleTextStyle: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                    ),
                    titleCentered: true,
                  ),
                  // rowHeight: 20,
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                    ),
                    weekendStyle: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                    // decoration: BoxDecoration(
                    //     border: BorderDirectional(
                    //         bottom: BorderSide(color: Colors.black)))
                  ),
                  calendarBuilders: CalendarBuilders(
                    // Mengubah warna hari dalam jangkauan _rangeStartDay menjadi pink
                    defaultBuilder: (context, date, _) {
                      if (date.isAfter(
                                  _rangeStartDay.subtract(Duration(days: 1))) &&
                              date.isBefore(
                                  _rangeEndDay.add(Duration(days: 1))) ||
                          date.isAfter(_rangeStartDayplus30) &&
                              date.isBefore(
                                  _rangeEndDayplus30.add(Duration(days: 1))) ||
                          date.isAfter(_rangeStartDayminus30) &&
                              date.isBefore(
                                  _rangeEndDayminus30.add(Duration(days: 1))) ||
                          date.isAtSameMomentAs(_rangeStartDay)) {
                        // Ini adalah hari dalam jangkauan _rangeStartDay
                        return Container(
                          margin: EdgeInsets.all(3),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.pink
                                .withOpacity(0.5), // Warna pink dengan opacity
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        );
                      } else {
                        // Ini adalah hari di luar jangkauan _rangeStartDay
                        return null; // Kembalikan null untuk menggunakan styling default
                      }
                    },
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              // decoration: BoxDecoration(back),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(width: 1, color: Colors.red),
                                  color: AppColors.pink1),
                              width: 10,
                              height: 10,
                            ),
                            SizedBox(
                              width: 7,
                            ),
                            Text(
                              'Possible start of period',
                              style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        // Text(
                        //   'Possible start of period',
                        //   style: TextStyle(
                        //       fontFamily: 'Satoshi',
                        //       fontSize: 10,
                        //       fontWeight: FontWeight.bold),
                        // )
                      ],
                    ),
                    SizedBox(
                      height: 35,
                      width: 70,
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(AppColors.pink1)),
                        onPressed: () {
                          // Handle button press
                          _showMarkDialog(context);
                        },
                        child: Text(
                          'Mark My Period',
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Divider(
                  color: Colors.black,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Statistics',
                  style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.width / 2 - 50,
                      width: MediaQuery.of(context).size.width / 2 - 50,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Last Cycle Length',
                            style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset('images/Union.png'),
                              Text(
                                '32 days',
                                style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                        255, 251, 85, 126)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context).size.width / 2 - 50,
                      width: MediaQuery.of(context).size.width / 2 - 50,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next Period',
                            style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                  width: 120,
                                  height: 110,
                                  // color: Colors.amber,
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Image.asset('images/phase.png')
                                            ])
                                      ])),
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
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
                                              '7 Days',
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
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Divider(
                  color: Colors.black,
                ),
                SizedBox(
                  height: 15,
                ),

                Container(
                  // height: MediaQuery.of(context).size.height / 2,
                  // width: MediaQuery.of(context).size.width / 2,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      children: [
                        Text(
                          'Cycle History',
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '(Last 5 Months)',
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 159, 159, 159)),
                        ),
                        BarChartExample(),
                        SizedBox(
                          width: 300,
                          child: Divider(
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: 3,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                                'Normal Cycle : ${startCycle} - ${endCycle} Days',
                                style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 12,
                                    // fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0))),
                            Text('Regular',
                                style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black))
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
                // LineChart(
                //   data: [0.29, 0.29, 0.34, 0.32, 0.30],
                //   width: 300,
                //   height: 200,
                //   strokeWidth: 2,
                //   color: Colors.blue,
                //   labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePageChange() {
    if (_focusedDay.isAfter(_previousFocusedMonth)) {
      _rangeStartDay = _rangeStartDay.add(const Duration(days: 30));
      _rangeStartDayplus30 = _rangeStartDayplus30.add(const Duration(days: 30));
      _rangeStartDayminus30 =
          _rangeStartDayminus30.add(const Duration(days: 30));

      _rangeEndDay = _rangeEndDay.add(const Duration(days: 30));
      _rangeEndDayplus30 = _rangeEndDayplus30.add(const Duration(days: 30));
      _rangeEndDayminus30 = _rangeEndDayminus30.add(const Duration(days: 30));
    } else if (_focusedDay.isBefore(_previousFocusedMonth)) {
      _rangeStartDay = _rangeStartDay.subtract(const Duration(days: 30));
      _rangeStartDayplus30 =
          _rangeStartDayplus30.subtract(const Duration(days: 30));
      _rangeStartDayminus30 =
          _rangeStartDayminus30.subtract(const Duration(days: 30));

      _rangeEndDay = _rangeEndDay.subtract(const Duration(days: 30));
      _rangeEndDayplus30 =
          _rangeEndDayplus30.subtract(const Duration(days: 30));
      _rangeEndDayminus30 =
          _rangeEndDayminus30.subtract(const Duration(days: 30));
    }
    _previousFocusedMonth = _focusedDay;
  }
}

// class LineChart extends StatelessWidget {
//   final List<double> data;
//   final double width;
//   final double height;
//   final double strokeWidth;
//   final Color color;
//   final List<String> labels;

//   LineChart({
//     required this.data,
//     this.width = double.infinity,
//     this.height = double.infinity,
//     this.strokeWidth = 2.0,
//     this.color = Colors.blue,
//     required this.labels,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           height: 100,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: labels.length,
//             itemBuilder: (context, index) {
//               return Text(
//                 labels[index],
//                 style: TextStyle(fontSize: 16),
//               );
//             },
//           ),
//         ),
//         CustomPaint(
//           size: Size(width, height),
//           painter: LineChartPainter(data, strokeWidth, color),
//         ),
//       ],
//     );
//   }
// }

// class LineChartPainter extends CustomPainter {
//   final List<double> data;
//   final double strokeWidth;
//   final Color color;

//   LineChartPainter(this.data, this.strokeWidth, this.color);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = strokeWidth
//       ..style = PaintingStyle.stroke;

//     final path = Path();

//     if (data.isNotEmpty) {
//       path.moveTo(0, size.height - (size.height * data[0]));

//       for (int i = 1; i < data.length; i++) {
//         path.lineTo(i * (size.width / (data.length - 1)),
//             size.height - (size.height * data[i]));
//       }

//       canvas.drawPath(path, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant LineChartPainter oldDelegate) {
//     return oldDelegate.data != data ||
//         oldDelegate.strokeWidth != strokeWidth ||
//         oldDelegate.color != color;
//   }
// }

class BarChartExample extends StatelessWidget {
  final List<int> data = [25, 34, 30, 29, 35];
  final List<String> labels = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 250,
        // color: Colors.amber,
        padding: EdgeInsets.all(16.0),
        child: BarChart(
          data: data,
          labels: labels,
        ),
      ),
    );
    // Scaffold(
    //   appBar: AppBar(
    //     title: Text('Bar Chart Example'),
    //   ),
    //   body: Center(
    //     child: Container(
    //       padding: EdgeInsets.all(16.0),
    //       child: BarChart(
    //         data: data,
    //         labels: labels,
    //       ),
    //     ),
    //   ),
    // );
  }
}

class BarChart extends StatelessWidget {
  final List<int> data;
  final List<String> labels;

  BarChart({required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          height: 210.0,
          child: ListView.builder(
            itemCount: data.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              return Bar(
                label: labels[index],
                value: data[index],
                maxValue: data
                    .reduce(
                        (value, element) => value > element ? value : element)
                    .toDouble(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class Bar extends StatelessWidget {
  final String label;
  final int value;
  final double maxValue;

  Bar({required this.label, required this.value, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Text(
        //   label,
        //   style: TextStyle(
        //     fontWeight: FontWeight.bold,
        //     fontSize: 16.0,
        //   ),
        // ),
        SizedBox(height: 10.0),
        Container(
          decoration: BoxDecoration(
            color: AppColors.pink1,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
          ),
          width: 50.0,
          height: (value / maxValue) * 170,
          // color: Colors.blue,
          // child: Center(
          //   child:
          // ),
        ),
        SizedBox(
          width: 60,
        ),
        Container(
          height: 30,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              value.toString(),
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 78, 78, 78)),
            ),
          ),
        ),
        // Text('data')
      ],
    );
  }
}

Future<void> _showMarkDialog(BuildContext context) async {
  late TextEditingController dateInputController = TextEditingController();
  late TextEditingController dateInputControllerend = TextEditingController();
  bool dontKnowSelected = false;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Container(
          height: 190,
          child: Column(
            children: [
              SizedBox(
                height: 5,
              ),
              const Text(
                'When did your last period start ?',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                            controller: dateInputController,
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1950),
                                lastDate: DateTime(2050),
                              );

                              if (pickedDate != null) {
                                dateInputController.text =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              const Text(
                'When did your last period end ?',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                            controller: dateInputControllerend,
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1950),
                                lastDate: DateTime(2050),
                              );

                              if (pickedDate != null) {
                                dateInputControllerend.text =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    // const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
        // const SingleChildScrollView(
        //   child: ListBody(
        //     children: <Widget>[
        //       Column(
        //         children: [Text('data'),

        //         ],
        //       )
        //     ],
        //   ),
        // ),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.pink1),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Done', style: TextStyle(color: AppColors.pink1)),
            onPressed: () {
              if (dateInputController.text.isNotEmpty &&
                  dateInputControllerend.text.isNotEmpty) {
                editData(dateInputController.text, dateInputControllerend.text);
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

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

Future<void> editData(dateStartEdit, dateEndEdit) async {
  dateStartEdit = dateStartEdit;
  dateEndEdit = dateEndEdit;
  final body = {
    'start_date': dateStartEdit,
    'end_date': dateEndEdit,
  };
  final id = await getCurrentUser();
  final url = "http://10.0.2.2:8000/api/catatanhaids/$id";
  final uri = Uri.parse(url);
  final response = await http.put(uri, body: jsonEncode(body), headers: {
    'Content-Type': 'application/json',
    'Authorization': '${AuthService.token}'
  });

  print(response.statusCode);
  print(response.body);
}

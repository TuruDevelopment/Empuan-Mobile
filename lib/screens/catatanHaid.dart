import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
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
    final url = 'http://192.168.8.48:8000/api/users/current';
    final uri = Uri.parse(url);

    final response =
        await http.get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
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

    final url = 'http://192.168.8.48:8000/api/catatanhaids/$userid';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});

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

    // Calculate countdown to next period (same as HomePage)
    Duration difference = _rangeStartDayplus30.difference(DateTime.now());
    int countdown = difference.inDays;

    print("start date $_rangeStartDay");
    print("end date $_rangeEndDay");
    print("start date plus$_rangeStartDayplus30");
    print("end date plus $_rangeEndDayplus30");
    print("start date minus$_rangeStartDayminus30");
    print("end date minus $_rangeEndDayminus30");
    print("countdown to next period: $countdown days");
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.accent.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Modern Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Period Tracker',
                            style: TextStyle(
                              fontFamily: 'Brodies',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Track your cycle',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Calendar Card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TableCalendar(
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
                            calendarStyle: CalendarStyle(
                              defaultTextStyle: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              weekendTextStyle: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
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
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            headerStyle: const HeaderStyle(
                              titleTextStyle: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                              formatButtonVisible: false,
                              titleCentered: true,
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: AppColors.primary,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: AppColors.primary,
                              ),
                            ),
                            // rowHeight: 20,
                            daysOfWeekStyle: const DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              weekendStyle: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                              // decoration: BoxDecoration(
                              //     border: BorderDirectional(
                              //         bottom: BorderSide(color: Colors.black)))
                            ),
                            calendarBuilders: CalendarBuilders(
                              // Mengubah warna hari dalam jangkauan _rangeStartDay menjadi pink
                              defaultBuilder: (context, date, _) {
                                if (date.isAfter(_rangeStartDay
                                            .subtract(Duration(days: 1))) &&
                                        date.isBefore(_rangeEndDay
                                            .add(Duration(days: 1))) ||
                                    date.isAfter(_rangeStartDayplus30) &&
                                        date.isBefore(_rangeEndDayplus30
                                            .add(Duration(days: 1))) ||
                                    date.isAfter(_rangeStartDayminus30) &&
                                        date.isBefore(_rangeEndDayminus30
                                            .add(Duration(days: 1))) ||
                                    date.isAtSameMomentAs(_rangeStartDay)) {
                                  // Ini adalah hari dalam jangkauan _rangeStartDay
                                  return Container(
                                    margin: const EdgeInsets.all(3),
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary.withOpacity(0.2),
                                      border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${date.day}',
                                        style: const TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
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
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Legend and Mark Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withOpacity(0.2),
                                  border: Border.all(
                                    width: 1.5,
                                    color: AppColors.primary.withOpacity(0.4),
                                  ),
                                ),
                                width: 12,
                                height: 12,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Period days',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 40,
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
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _showMarkDialog(context);
                              },
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Mark Period',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      // Section Header
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Stats Cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Last Cycle Card
                          Expanded(
                            child: Container(
                              height:
                                  MediaQuery.of(context).size.width / 2 - 50,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Last Cycle',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary.withOpacity(0.1),
                                    ),
                                    child: const Text(
                                      '32',
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'days',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Next Period Card
                          Expanded(
                            child: Container(
                              height:
                                  MediaQuery.of(context).size.width / 2 - 50,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Next Period',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'in',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.secondary.withOpacity(0.2),
                                          AppColors.accent.withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      '$countdown',
                                      style: const TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'days',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Cycle History Card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text(
                                'Cycle History',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                '(Last 5 Months)',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              BarChartExample(),
                              Container(
                                width: 280,
                                height: 1,
                                color: AppColors.accent.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    'Normal: $startCycle-$endCycle days',
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Regular',
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
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
        const SizedBox(height: 10.0),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
          ),
          width: 50.0,
          height: (value / maxValue) * 170,
        ),
        const SizedBox(width: 60),
        Container(
          height: 30,
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value.toString(),
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showMarkDialog(BuildContext context) async {
  late TextEditingController dateInputController = TextEditingController();
  late TextEditingController dateInputControllerend = TextEditingController();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'When did your last period start?',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_month),
                      border: InputBorder.none,
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
              const SizedBox(height: 16),
              const Text(
                'When did your last period end?',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_month),
                      border: InputBorder.none,
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
  final url = 'http://192.168.8.48:8000/api/users/current';
  final uri = Uri.parse(url);

  final response =
      await http.get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
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
  final url = "http://192.168.8.48:8000/api/catatanhaids/$id";
  final uri = Uri.parse(url);
  final response = await http.put(uri, body: jsonEncode(body), headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthService.token}'
  });

  print(response.statusCode);
  print(response.body);
}

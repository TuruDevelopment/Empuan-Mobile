import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/services/api_client.dart';
import 'package:Empuan/styles/style.dart';

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
  String errorMessage = "";

  // --- DATA VARIABEL ---
  String displayLastCycle = "-";
  String displayAvgCycle = "-";
  String displayNextIn = "-";

  // --- CHART VARIABEL ---
  List<int> chartData = [];
  List<String> chartLabels = [];
  String analysisText = "Normal: 21-35 days";
  String statusText = "-";
  Color statusColor = AppColors.textSecondary;

  // --- KALENDER VARIABEL ---
  late DateTime _focusedDay = DateTime.now();
  late DateTime _rangeStartDay = widget.startdate;
  late DateTime _rangeStartDayplus30 =
      widget.startdate.add(const Duration(days: 30));
  late DateTime _rangeStartDayminus30 =
      widget.startdate.subtract(const Duration(days: 30));
  late DateTime _rangeEndDay = widget.enddate;
  late DateTime _rangeEndDayplus30 =
      widget.enddate.add(const Duration(days: 30));
  late DateTime _rangeEndDayminus30 =
      widget.enddate.subtract(const Duration(days: 30));
  late DateTime _previousFocusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    print("🚀 DEBUG: CatatanHaid initialized");
    print("🚀 DEBUG: Initial startdate: ${widget.startdate}");
    print("🚀 DEBUG: Initial enddate: ${widget.enddate}");
    print("🚀 DEBUG: API Base URL: ${ApiConfig.baseUrl}");
    _loadData();
  }

  void _loadData() {
    print("🔄 DEBUG: Loading data...");
    getDataList();
    getStatsData();
  }

  // 1. API: Get List (Untuk Kalender)
  Future<void> getDataList() async {
    final url = '${ApiConfig.baseUrl}/catatan-haid';
    print("📅 DEBUG: Calling calendar API: $url");

    try {
      final response = await ApiClient.get(url);

      print("📅 DEBUG: Calendar Response Status: ${response.statusCode}");
      print("📅 DEBUG: Calendar Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];

        print("📅 DEBUG: Data is null? ${data == null}");

        if (data != null &&
            data['start_date'] != null &&
            data['end_date'] != null) {
          print("📅 DEBUG: Start Date: ${data['start_date']}");
          print("📅 DEBUG: End Date: ${data['end_date']}");

          if (mounted) {
            setState(() {
              _rangeStartDay = DateTime.parse(data['start_date']);
              _rangeEndDay = DateTime.parse(data['end_date']);
            });
            print("✅ DEBUG: Calendar dates updated successfully");
          }
        } else {
          print("⚠️ DEBUG: Calendar data is null or missing dates");
        }
      } else {
        print("❌ DEBUG: Calendar API error ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      print("❌ DEBUG: Calendar Error: $e");
      print("❌ DEBUG: Stack trace: $stackTrace");
    }
  }

// 2. API: Get Stats (Untuk Card & Chart) - FIXED VERSION
// Update logic di dalam class _CatatanHaidState

  Future<void> getStatsData() async {
    if (AuthService.token == null || AuthService.token!.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "Anda belum login. Silakan login ulang.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final url = '${ApiConfig.baseUrl}/catatan-haid/stats?months=6';

    try {
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];

        if (data != null && mounted) {
          setState(() {
            // --- 1. PARSING STATS CARDS (Durasi Mens / Bleeding Days) ---

            // Ambil overview dari response baru
            var overview = data['overview'] ?? {};

            // Last Cycle (Menampilkan durasi mens terakhir, misal: 5 hari)
            displayLastCycle =
                overview['last_bleeding_length']?.toString() ?? "0";

            // Avg Cycle (Menampilkan rata-rata durasi mens, misal: 6 hari)
            displayAvgCycle =
                overview['avg_bleeding_length']?.toString() ?? "0";

            // Next In (Prediksi sisa hari)
            var prediction = data['prediction'] ?? {};
            displayNextIn = prediction['days_remaining']?.toString() ?? "-";

            // --- 2. PARSING CHART DATA (Durasi Mens History) ---
            var chartObj = data['chart_data'] ?? {};
            List<dynamic> rawHistory = chartObj['bleeding_history'] ?? [];

            chartData = [];
            chartLabels = [];

            // Logika Ambil 5 Data Terakhir agar grafik rapi
            int totalData = rawHistory.length;
            int startIndex = totalData > 5 ? totalData - 5 : 0;

            for (int i = startIndex; i < totalData; i++) {
              int val = int.tryParse(rawHistory[i].toString()) ?? 0;
              chartData.add(val);
              chartLabels.add(val.toString());
            }

            // --- 3. STATUS TEXT ---
            // Analisis sederhana berdasarkan durasi mens (Normal: 2-7 hari)
            if (chartData.isNotEmpty) {
              double sum = 0;
              for (var n in chartData) sum += n;
              double localAvg = sum / chartData.length;

              analysisText = "Average Period: ${localAvg.round()} days";

              // Logika Medis Durasi Mens Normal (2-7 Hari)
              if (localAvg >= 2 && localAvg <= 8) {
                statusText = "Normal Period";
                statusColor = AppColors.secondary;
              } else {
                statusText = "Irregular Period";
                statusColor = AppColors.error;
              }
            } else {
              analysisText = "No data yet";
              statusText = "-";
              statusColor = AppColors.textSecondary;
            }
          });
        }
      } else {
        print("❌ Error Stats: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error Exception: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recalculate Calendar
    _rangeStartDayplus30 = _rangeStartDay.add(const Duration(days: 30));
    _rangeStartDayminus30 = _rangeStartDay.subtract(const Duration(days: 30));
    _rangeEndDayplus30 = _rangeEndDay.add(const Duration(days: 30));
    _rangeEndDayminus30 = _rangeEndDay.subtract(const Duration(days: 30));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.accent.withOpacity(0.1)
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // --- HEADER ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.calendar_month_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Period Tracker',
                              style: TextStyle(
                                  fontFamily: 'Brodies',
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                          Text('Track your cycle',
                              style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- ERROR MESSAGE (Jika Ada) ---
              if (errorMessage.isNotEmpty)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(errorMessage,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12))),
                    ],
                  ),
                ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // --- CALENDAR CARD (UI Sama) ---
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.3),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2010, 10, 16),
                            lastDay: DateTime.utc(2030, 3, 14),
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
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              todayDecoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle),
                              todayTextStyle: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            headerStyle: const HeaderStyle(
                              titleTextStyle: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primary),
                              formatButtonVisible: false,
                              titleCentered: true,
                              leftChevronIcon: Icon(Icons.chevron_left,
                                  color: AppColors.primary),
                              rightChevronIcon: Icon(Icons.chevron_right,
                                  color: AppColors.primary),
                            ),
                            calendarBuilders: CalendarBuilders(
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
                                  return Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            AppColors.primary.withOpacity(0.2)),
                                    child: Center(
                                        child: Text('${date.day}',
                                            style: const TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary))),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tombol Mark Period
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(colors: [
                              AppColors.primary,
                              AppColors.primaryVariant
                            ]),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: () {
                              _showMarkDialog();
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_calendar_rounded,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text('Mark Period',
                                    style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- TITLE STATS ---
                      Row(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.analytics_rounded,
                                  color: AppColors.primary, size: 20)),
                          const SizedBox(width: 12),
                          const Text('Your Statistics',
                              style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // --- STATS CARDS ---
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                                  icon: Icons.event_note_rounded,
                                  label: 'Last Cycle',
                                  value: displayLastCycle,
                                  unit: 'days',
                                  color: AppColors.primary)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(
                                  icon: Icons.timeline_rounded,
                                  label: 'Avg Cycle',
                                  value: displayAvgCycle,
                                  unit: 'days',
                                  color: AppColors.secondary)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(
                                  icon: Icons.event_available_rounded,
                                  label: 'Next In',
                                  value: displayNextIn,
                                  unit: 'days',
                                  color: AppColors.accent)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- CYCLE HISTORY CHART SECTION ---
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.3),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.accent.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: AppColors.secondary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Icon(Icons.bar_chart_rounded,
                                          color: AppColors.secondary,
                                          size: 18)),
                                  const SizedBox(width: 10),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Cycle History',
                                            style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary)),
                                        Text(
                                            chartData.isEmpty
                                                ? 'No Data'
                                                : 'Last ${chartData.length} Cycles',
                                            style: const TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppColors.textSecondary)),
                                      ]),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // --- CHART RENDER ---
                              (isLoading)
                                  ? const SizedBox(
                                      height: 150,
                                      child: Center(
                                          child: CircularProgressIndicator()))
                                  : (chartData.isEmpty)
                                      ? const SizedBox(
                                          height: 150,
                                          child: Center(
                                              child: Text(
                                                  "No history data found.")))
                                      : BarChartExample(
                                          data: chartData, labels: chartLabels),

                              Container(
                                  width: 280,
                                  height: 1,
                                  color: AppColors.accent.withOpacity(0.3)),
                              const SizedBox(height: 12),

                              // --- INFO & STATUS ---
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(analysisText,
                                      style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(statusText,
                                        style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor)),
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

  Widget _buildStatCard(
      {required IconData icon,
      required String label,
      required String value,
      required String unit,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
          Text(unit,
              style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _handlePageChange() {
    // Logic calendar navigation - same as before
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

  Future<void> _showMarkDialog() async {
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
                const Text('When did your last period start?',
                    style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Container(
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: TextFormField(
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.calendar_month),
                                border: InputBorder.none),
                            controller: dateInputController,
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime(2050));
                              if (pickedDate != null) {
                                dateInputController.text =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                              }
                            }))),
                const SizedBox(height: 16),
                const Text('When did your last period end?',
                    style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Container(
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: TextFormField(
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.calendar_month),
                                border: InputBorder.none),
                            controller: dateInputControllerend,
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime(2050));
                              if (pickedDate != null) {
                                dateInputControllerend.text =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                              }
                            }))),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.pink1)),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            TextButton(
                child: const Text('Done',
                    style: TextStyle(color: AppColors.pink1)),
                onPressed: () async {
                  if (dateInputController.text.isNotEmpty &&
                      dateInputControllerend.text.isNotEmpty) {
                    await createData(
                        dateInputController.text, dateInputControllerend.text);
                    // Refresh data setelah create (Tanpa User ID)
                    getDataList();
                    getStatsData();
                  }
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }
}

// --- BAR CHART WIDGETS ---
class BarChartExample extends StatelessWidget {
  final List<int> data;
  final List<String> labels;

  BarChartExample({required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        // Sedikit menambah tinggi container agar teks 'days' tidak terpotong
        height: 260,
        padding: const EdgeInsets.all(0.0),
        child: BarChart(data: data, labels: labels),
      ),
    );
  }
}

class BarChart extends StatelessWidget {
  final List<int> data;
  final List<String> labels;

  BarChart({required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    // Validasi data kosong
    double maxValue = 1;
    if (data.isNotEmpty) {
      maxValue = data.reduce(math.max).toDouble();
      if (maxValue == 0) maxValue = 1;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          // Menggunakan Expanded agar mengisi sisa ruang
          child: ListView.builder(
            itemCount: data.length,
            scrollDirection: Axis.horizontal,
            // Menambahkan padding di awal dan akhir list agar grafik tidak mepet pinggir
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemBuilder: (BuildContext context, int index) {
              return Bar(
                label: labels[index],
                value: data[index],
                maxValue: maxValue,
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
    return Container(
      // [PERUBAHAN 1] Memberi jarak optimal (margin kiri-kanan)
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // Batang Grafik
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            // Sedikit mengecilkan lebar batang agar terlihat lebih elegan
            width: 45.0,
            // Menghitung tinggi proporsional (max tinggi batang 150)
            height: (value / maxValue) * 150,
          ),

          const SizedBox(height: 12), // Jarak antara batang dan teks

          // [PERUBAHAN 2] Menambah keterangan "days"
          Column(
            children: [
              Text(
                label, // Angka (misal: 5)
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                "days", // Keterangan unit
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10, // Ukuran lebih kecil
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Fungsi helper API (createData, editData) tetap sama
Future<void> createData(dateStart, dateEnd) async {
  final body = {'start_date': dateStart, 'end_date': dateEnd};
  final url = "${ApiConfig.baseUrl}/catatan-haid";

  print("💾 DEBUG: Creating period data");
  print("💾 DEBUG: URL: $url");
  print("💾 DEBUG: Body: $body");
  print("💾 DEBUG: Token: ${AuthService.token?.substring(0, 20)}...");

  try {
    final response = await ApiClient.post(url, body: body);

    print("💾 DEBUG: Create Response Status: ${response.statusCode}");
    print("💾 DEBUG: Create Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ DEBUG: Period data created successfully");
    } else {
      print("❌ DEBUG: Failed to create data");
    }
  } catch (e, stackTrace) {
    print("❌ DEBUG: Error creating data: $e");
    print("❌ DEBUG: Stack trace: $stackTrace");
  }
}

// --- FUNGSI GET DATA LIST (Global) ---
Future<void> getDataList() async {
  // Fungsi dummy global jika diperlukan
}

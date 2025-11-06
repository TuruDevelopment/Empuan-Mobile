import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Empuan/screens/HomePage.dart';
import 'package:Empuan/screens/catatanHaid.dart';
import 'package:Empuan/screens/more.dart';
import 'package:Empuan/screens/nav_bar.dart';
import 'package:Empuan/screens/nav_model.dart';
import 'package:Empuan/screens/panggilPuan.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:whatsapp/whatsapp.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:direct_sms/direct_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // bool isLoading = true;

  // void initState() {
  //   super.initState();

  // }

  final homeNavKey = GlobalKey<NavigatorState>();
  final haidNavKey = GlobalKey<NavigatorState>();
  final panggilNavKey = GlobalKey<NavigatorState>();
  final moreNavKey = GlobalKey<NavigatorState>();
  int _selectedTab = 0;

  int get selectedTab => _selectedTab;

  set selectedTab(int value) {
    _selectedTab = value;
  }

  // void initState() {

  // }

  bool isLoading = true;
  List<NavModel> items = [];
  List<String> phoneNumbers = [];

  // late DateTime _startdate = DateTime.now();
  // late DateTime _enddate = DateTime.now();

  late DateTime _startdate = DateTime.now();
  late DateTime _enddate = DateTime.now();

  bool sosActive = false;

  @override
  void initState() {
    super.initState();

    getCurrentUser().then((userid) {
      if (userid != null) {
        getData(userid);
      }
    });
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    //   getDataKontakAman();
    // });
    items = [
      NavModel(
        page: HomePage(
          startdate: _startdate,
          enddate: _enddate,
        ),
        navKey: homeNavKey,
      ),
      NavModel(
        page: CatatanHaid(
          startdate: _startdate,
          enddate: _enddate,
        ),
        navKey: haidNavKey,
      ),
      NavModel(
        page: PanggilPuan(),
        navKey: panggilNavKey,
      ),
      NavModel(
        page: More(),
        navKey: moreNavKey,
      ),
    ];
    // getDataKontakAman();
  }

  WhatsApp whatsapp = WhatsApp();
  Position? _currentPosition;
  final Telephony telephony = Telephony.instance;
  var directSms = DirectSms();

  final List listNum = [
    '6285773030388',
    '6281368701176',
    '62895334296207',
    '6288269841977'
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (items[selectedTab].navKey.currentState?.canPop() ?? false) {
          items[selectedTab].navKey.currentState?.pop();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: selectedTab,
          children: items
              .map((page) => Navigator(
                    key: page.navKey,
                    onGenerateInitialRoutes: (navigator, initialRoute) {
                      return [
                        MaterialPageRoute(builder: (context) => page.page)
                      ];
                    },
                  ))
              .toList(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          margin: const EdgeInsets.only(top: 10),
          height: 70,
          width: 70,
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: sosActive
                      ? [
                          AppColors.secondary,
                          AppColors.secondary.withOpacity(0.8),
                        ]
                      : [
                          AppColors.error,
                          AppColors.error.withOpacity(0.8),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: sosActive
                        ? AppColors.secondary.withOpacity(0.4)
                        : AppColors.error.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                sosActive ? Icons.close_rounded : Icons.crisis_alert_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              if (sosActive) {
                // Just toggle off
                setState(() {
                  sosActive = false;
                });
              } else {
                // Toggle on and show dialog
                setState(() {
                  sosActive = true;
                });
                location();
                _showLocationSharedDialog();
              }
            },
          ),
        ),
        bottomNavigationBar: selectedTab == 99
            ? null
            : NavBar(
                pageIndex: selectedTab,
                onTap: (index) {
                  if (index == selectedTab) {
                    items[index]
                        .navKey
                        .currentState
                        ?.popUntil((route) => route.isFirst);
                  } else {
                    setState(() {
                      selectedTab = index;
                    });
                  }
                },
              ),
      ),
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
            _startdate = DateTime.parse(data['start_date']);
            _enddate = DateTime.parse(data['end_date']);
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

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> location() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission || !mounted) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
    }).catchError((e) {
      debugPrint(e);
    });

    print('LAT: ${_currentPosition?.latitude ?? ""}');
    print('LNG: ${_currentPosition?.longitude ?? ""}');

    _launchUrl(_currentPosition?.latitude, _currentPosition?.longitude);
  }

  Future<void> _launchUrl(double? lat, double? long) async {
    Uri _url = Uri.parse('https://www.google.com/maps/search/${lat},${long}');
    print(_url);
    // if (!await launchUrl(_url)) {
    //   throw Exception('Could not launch $_url');
    // }

    // sendSms(_url);
    // telephony.sendSmsByDefaultApp(to: "6285773030388", message: "${_url}");
    final permission = Permission.sms.request();
    if (await permission.isGranted) {
      for (var i = 0; i < listNum.length; i++) {
        directSms.sendSms(message: "${_url}", phone: "${listNum[i]}");
      }
      // for (var i = 0; i < phoneNumbers.length; i++) {
      //   print("${phoneNumbers[i]}");
      //   directSms.sendSms(
      //       message: "Help Your Friend !!! \n${_url}",
      //       phone: "${phoneNumbers[i]}");
      // }
      // for (var phoneNumber in phoneNumbers) {
      //   print(phoneNumber);
      //   directSms.sendSms(
      //       message: "Help Your Friend !!! \n${_url}", phone: phoneNumber);
      // }
    }
  }

  Future<void> getDataKontakAman() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url = 'http://192.168.8.48:8000/api/kontakamans';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['data'] ?? [] as List;

      // Clear the phoneNumbers list before adding new numbers
      phoneNumbers.clear();

      // Extract phone numbers from each data entry and add them to phoneNumbers list
      for (var data in result) {
        final phoneNumber = data['phoneNumber'].toString();
        print('phone number: $phoneNumber');
        phoneNumbers.add(phoneNumber);
      }

      setState(() {
        phoneNumbers =
            phoneNumbers; // Update dataContact with the obtained data
      });
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik kontak' + response.body);
  }

  void _showLocationSharedDialog() {
    showDialog(
      barrierColor: Colors.black26,
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Use Timer to auto-close dialog
        Timer(const Duration(seconds: 3), () {
          // Check if dialog context is still mounted
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary,
                        AppColors.secondary.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Location Shared",
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your location has been shared\nwith your emergency contacts",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:convert';
import 'dart:async';
import 'dart:io' if (dart.library.html) 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/screens/HomePage.dart';
import 'package:Empuan/screens/catatanHaid.dart';
import 'package:Empuan/screens/more.dart';
import 'package:Empuan/screens/nav_bar.dart';
import 'package:Empuan/screens/nav_model.dart';
import 'package:Empuan/screens/panggilPuan.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:direct_sms/direct_sms.dart';

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
  final DirectSms directSms = DirectSms();

  @override
  void initState() {
    super.initState();

    getCurrentUser().then((userid) {
      if (userid != null) {
        getData(userid);
        getDataKontakAman(); // Load emergency contacts on init
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

  Position? _currentPosition;

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
        resizeToAvoidBottomInset: false,
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
        bottomNavigationBar: selectedTab == 99
            ? null
            : NavBar(
                pageIndex: selectedTab,
                sosActive: sosActive,
                onPanicPressed: () {
                  if (sosActive) {
                    setState(() {
                      sosActive = false;
                    });
                  } else {
                    setState(() {
                      sosActive = true;
                    });
                    location();
                    _showLocationSharedDialog();
                  }
                },
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

  Future<int?> getCurrentUser() async {
    final url = '${ApiConfig.baseUrl}/me';
    final uri = Uri.parse(url);

    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['data'] != null) {
        final data = jsonData['data'];
        if (data.containsKey('id')) {
          return data['id'];
        }
      }
    }
    return null;
  }

  Future<void> getData(int userid) async {
    setState(() {
      isLoading = true;
    });

    final url = '${ApiConfig.baseUrl}/catatan-haid';
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});

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

    // Fetch emergency contacts first
    print('Fetching emergency contacts before sending SMS...');
    await getDataKontakAman();

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
    String message =
        '🚨 DARURAT! Saya membutuhkan bantuan segera. Ini adalah pesan otomatis dari aplikasi Empuan. Mohon periksa lokasi saya: https://www.google.com/maps/search/${lat},${long}';

    print('Sending emergency SMS to contacts');
    print('Location URL: $_url');
    print('Emergency contacts count: ${phoneNumbers.length}');
    print('Emergency contacts: $phoneNumbers');

    // SMS functionality only works on mobile platforms
    if (!kIsWeb) {
      try {
        int successCount = 0;
        int failCount = 0;

        // Send to emergency contacts from database if available
        if (phoneNumbers.isNotEmpty) {
          for (var i = 0; i < phoneNumbers.length; i++) {
            print('Attempting to send SMS to: ${phoneNumbers[i]}');
            try {
              await directSms.sendSms(
                phone: phoneNumbers[i],
                message: message,
              );
              successCount++;
              print('✓ SMS sent successfully to ${phoneNumbers[i]}');
            } catch (e) {
              failCount++;
              print('✗ Exception sending to ${phoneNumbers[i]}: $e');
            }
          }
          print('=== SMS SUMMARY ===');
          print('Total contacts: ${phoneNumbers.length}');
          print('Successful: $successCount');
          print('Failed: $failCount');
        } else {
          // Fallback to hardcoded numbers if no emergency contacts in database
          print('No emergency contacts found, using default numbers');
          for (var i = 0; i < listNum.length; i++) {
            print('Attempting to send SMS to default: ${listNum[i]}');
            try {
              await directSms.sendSms(
                phone: listNum[i],
                message: message,
              );
              successCount++;
              print('✓ SMS sent successfully to ${listNum[i]}');
            } catch (e) {
              failCount++;
              print('✗ Exception sending to ${listNum[i]}: $e');
            }
          }
          print('=== SMS SUMMARY ===');
          print('Total default contacts: ${listNum.length}');
          print('Successful: $successCount');
          print('Failed: $failCount');
        }

        // Show result to user
        if (mounted && successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Emergency SMS sent to $successCount contact(s)',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
        } else if (mounted && failCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to send SMS to any contacts',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Error in SMS sending process: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Emergency SMS error: ${e.toString()}',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      print('Web platform: SMS not supported. Location: $_url');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'SMS not supported on web platform',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> getDataKontakAman() async {
    if (!mounted) return;

    // get data from form
    // submit data to the server
    final url = '${ApiConfig.baseUrl}/kontak-aman';
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['data'] ?? [] as List;

      // Extract phone numbers from each data entry
      List<String> tempPhoneNumbers = [];
      for (var data in result) {
        final phoneNumber = data['phoneNumber'].toString();
        print('Loading emergency contact: $phoneNumber');
        tempPhoneNumbers.add(phoneNumber);
      }

      // Update state with new phone numbers
      setState(() {
        phoneNumbers = tempPhoneNumbers;
      });

      print('Emergency contacts loaded: ${phoneNumbers.length} numbers');
      print('Phone numbers: $phoneNumbers');
    }

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
                    fontFamily: 'Plus Jakarta Sans',
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
                    fontFamily: 'Plus Jakarta Sans',
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

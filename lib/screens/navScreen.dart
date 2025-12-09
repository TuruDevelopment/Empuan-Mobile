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
import 'package:Empuan/services/api_client.dart';
import 'package:Empuan/styles/style.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

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

  void _buildItems() {
    items = [
      NavModel(
        page: HomePage(
          key: ValueKey(
              'home_${_startdate.toString()}'), // Force rebuild on data change
          startdate: _startdate,
          enddate: _enddate,
        ),
        navKey: homeNavKey,
      ),
      NavModel(
        page: CatatanHaid(
          key: ValueKey(
              'haid_${_startdate.toString()}'), // Force rebuild on data change
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
  }

  @override
  void initState() {
    super.initState();

    _buildItems(); // Initial build

    getCurrentUser().then((userid) {
      if (userid != null) {
        getData(userid);
        getDataKontakAman(); // Load emergency contacts on init
      }
    });
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
                onTap: (index) async {
                  if (index == selectedTab) {
                    items[index]
                        .navKey
                        .currentState
                        ?.popUntil((route) => route.isFirst);
                  } else {
                    setState(() {
                      selectedTab = index;
                    });

                    // Refresh data when switching to HomePage or CatatanHaid tab
                    if (index == 0 || index == 1) {
                      final userid = await getCurrentUser();
                      if (userid != null) {
                        await getData(userid);
                      }
                    }
                  }
                },
              ),
      ),
    );
  }

  Future<int?> getCurrentUser() async {
    final url = '${ApiConfig.baseUrl}/me';

    final response = await ApiClient.get(url);
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
    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['data'] != null) {
        final data = jsonData['data'];

        if (data['start_date'] != null && data['end_date'] != null) {
          print('[NAV_SCREEN] 🔄 Updating period data:');
          print('[NAV_SCREEN] Old: $_startdate to $_enddate');
          print(
              '[NAV_SCREEN] New: ${data['start_date']} to ${data['end_date']}');

          setState(() {
            _startdate = DateTime.parse(data['start_date']);
            _enddate = DateTime.parse(data['end_date']);
            _buildItems(); // Rebuild items with new data
          });

          print('[NAV_SCREEN] ✅ Period data updated and widgets rebuilt');
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

  Future<bool> _handleSmsPermission() async {
    print('📱 Checking SMS permission...');

    var status = await Permission.sms.status;
    print('📱 Current SMS permission status: $status');

    if (status.isDenied) {
      print('📱 SMS permission denied, requesting...');
      status = await Permission.sms.request();
      print('📱 SMS permission request result: $status');

      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('SMS permission is required to send emergency messages'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      print('📱 SMS permission permanently denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'SMS permission is permanently denied. Please enable it in settings.'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return false;
    }

    print('✅ SMS permission granted');
    return status.isGranted;
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
        '🚨 EMERGENCY! I need help immediately. This is an automated message from the Empuan app. Please check my location: https://www.google.com/maps/search/${lat},${long}';

    print('Sending emergency SMS to contacts');
    print('Location URL: $_url');
    print('Emergency contacts count: ${phoneNumbers.length}');
    print('Emergency contacts: $phoneNumbers');

    // SMS functionality only works on mobile platforms
    if (!kIsWeb) {
      // Check SMS permission before sending
      final hasSmsPermission = await _handleSmsPermission();
      if (!hasSmsPermission) {
        print('❌ SMS permission not granted, cannot send messages');
        return;
      }

      try {
        int successCount = 0;
        int failCount = 0;

        // Determine which contacts to use
        List<String> recipients =
            phoneNumbers.isNotEmpty ? phoneNumbers : listNum.cast<String>();

        if (recipients.isEmpty) {
          print('❌ No emergency contacts found');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No emergency contacts configured',
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
          return;
        }

        print('📱 Sending SMS to ${recipients.length} contacts: $recipients');

        // Use url_launcher to open SMS app with pre-filled message
        // Send to ALL recipients in one SMS (separated by semicolons)
        try {
          // Join all recipients with semicolons (Android) or commas (iOS)
          final String allRecipients = recipients.join(';');
          final String encodedMessage = Uri.encodeComponent(message);

          print('📱 Opening SMS for ALL contacts: $allRecipients');

          // Try multiple URI formats for compatibility
          List<Uri> urisToTry = [
            Uri.parse('sms:$allRecipients?body=$encodedMessage'),
            Uri.parse('smsto:$allRecipients?body=$encodedMessage'),
            Uri.parse(
                'sms:${recipients.join(",")}?body=$encodedMessage'), // comma separated
          ];

          bool launched = false;

          for (Uri smsUri in urisToTry) {
            try {
              // Use external application mode to ensure it opens in SMS app
              launched = await launchUrl(
                smsUri,
                mode: LaunchMode.externalApplication,
              );
              if (launched) {
                successCount = recipients.length;
                print(
                    '✅ SMS app opened for all ${recipients.length} contacts with URI: $smsUri');
                break;
              }
            } catch (e) {
              print('⚠️ Failed with URI $smsUri: $e');
            }
          }

          if (!launched) {
            failCount = recipients.length;
            print('❌ Cannot launch SMS - No SMS app found (emulator?)');
          }
        } catch (e) {
          print('❌ SMS Exception: $e');
          failCount = recipients.length;
        }

        print('=== SMS SUMMARY ===');
        print('Total contacts: ${recipients.length}');
        print('Successful: $successCount');
        print('Failed: $failCount');

        // Show appropriate message
        if (failCount > 0 && successCount == 0) {
          // All failed - likely emulator or no SMS app
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.phone_android, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No SMS app found. Please test on a real device.',
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
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
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
    final response = await ApiClient.get(url);
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tumpuan/screens/home.dart';
import 'package:tumpuan/screens/navScreen.dart';
import 'package:tumpuan/screens/mapScreen.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/services/tumpuanServices.dart';
import 'package:tumpuan/signUp/intro.dart';
import 'package:tumpuan/signUp/intro1.dart';
import 'package:tumpuan/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import 'package:whatsapp/whatsapp.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:direct_sms/direct_sms.dart';
import 'package:permission_handler/permission_handler.dart';

// import android.telephony.SmsManager;

class LoginPage extends StatefulWidget {
  final Map? login;

  const LoginPage({Key? key, this.login}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool visible = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool obscurePassword = false; // Added to track password visibility
  WhatsApp whatsapp = WhatsApp();
  String? _currentAddress;
  Position? _currentPosition;
  static const platform = const MethodChannel('sendSms');
  final Telephony telephony = Telephony.instance;
  var directSms = DirectSms();

  void initState() {
    super.initState();
    // getDataKontakAman();
    getData();
  }

  bool isLoading = true;
  List<String> phoneNumbers = [];
  List<dynamic> dataMore = [];
  // final List listNum = [
  //   '62895617896999',
  //   '6285773030388',
  //   '6281368701176',
  //   '62895334296207',
  //   '6282277842107'
  // ];
  final List listNum = [
    '6281368701176',
    '6283895832404',
    '62895334296207',
    '628159966712',
    '6285290176877',
    '6281285362705',
    '6285766996371',
    '6287781630337',
    '6281332040550',
    '6289638016161',
    '6285725177043',
    '62895389916688',
    '6285276251525',
    '6281377690667',
    '6282211114846',
    '6282277842107',
    '628119517675',
    '6282173320908',
    '6281332185362',
    '6281905634863',
    '62895414770917',
    '628995717130',
    '6285773030388',
    '628118895560',
    '6285861002700',
    '6281905538337',
    '6282297936064',
    '6288747566647',
    '628111915988',
    '6281388193216',
    '628198405395',
    '6281341457095',
    '6289643690621',
    '6288269841977',
    '6285156565719',
    '6285693070832'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tumpuan',
                  style: TextStyle(
                      fontFamily: 'Brodies',
                      color: Color.fromRGBO(251, 111, 146, 1),
                      fontSize: 40),
                ),
                const SizedBox(height: 40),
                buildTextField(
                  controller: usernameController,
                  obscureText: false,
                  hintText: 'Username',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),

                const SizedBox(
                  height: 20,
                ),
                //password
                buildTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  obscureText:
                      obscurePassword, // Pass the obscurePassword value
                  onTap: () {
                    setState(() {
                      obscurePassword =
                          !obscurePassword; // Toggle obscurePassword value
                    });
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                //sign in button
                SizedBox(
                  width: 100,
                  child: FilledButton(
                    onPressed:
                        // if (_formKey.currentState!.validate()) {
                        //   Navigator.of(context).pushReplacement(MaterialPageRoute(
                        //     builder: (context) => const MainScreen(),
                        //   ));
                        // }
                        doLogin,
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            const Color.fromRGBO(251, 111, 146, 1))),
                    child: const Text(
                      'Login',
                      style:
                          TextStyle(fontFamily: 'Satoshi', color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),
                // register button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Not a member?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      child: const Text(
                        'Register Now',
                        style: TextStyle(
                            color: Color.fromRGBO(251, 111, 146, 1),
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed:
                          // location
                          // share
                          () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => const Intro()));
                      },
                      //     () {
                      //   Navigator.of(context).pushReplacement(MaterialPageRoute(
                      //       builder: (context) => MapScreen()));
                      // },
                    )
                  ],
                ),
                // Text('LAT: ${_currentPosition?.latitude ?? ""}'),
                // Text('LNG: ${_currentPosition?.longitude ?? ""}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The rest of your code remains unchanged
  // ...

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    Function()? onTap,
    bool? obscureText, // Add the obscureText parameter
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextFormField(
        obscureText: obscureText ??
            true, // Set obscureText based on the parameter or default to false
        controller: controller,
        decoration: InputDecoration(
          suffixIcon: hintText == 'Password'
              ? IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: onTap as void Function()?,
                )
              : null,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
        onTap: onTap,
      ),
    );
  }

  doLogin() async {
    bool isValid = _formKey.currentState!.validate();
    if (isValid) {
      final username = usernameController.text;
      final password = passwordController.text;

      bool isSuccess =
          await AuthService().login(username: username, password: password);

      if (!isSuccess) {
        print(isSuccess);
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ));
      }
    }
  }

  Future<void> getData() async {
    // get data from form
    // submit data to the server
    final url = 'http://10.0.2.2:8000/api/ruangPuans';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      print('items kita' + json['data'].toString());
      final result = json['data'] ?? [] as List;
      setState(() {
        dataMore = result;
      });
    } else {}
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }

  // Contact aman darisini sampe abis

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
    if (!hasPermission) return;
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print('test');
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

    print("masuk ");
    if (await permission.isGranted) {
      for (var i = 0; i < listNum.length; i++) {
        print("${listNum[i]}");
        directSms.sendSms(
            message: "Help Your Friend !!!\n I'm in Trouble\n${_url}",
            phone: "${listNum[i]}");
      }
      // print("masukkkk");
      // for (var i = 0; i < phoneNumbers.length; i++) {
      //   print("${phoneNumbers[i]}");
      //   directSms.sendSms(
      //       message: "Help Your Friend !!! \n${_url}",
      //       phone: "${phoneNumbers[i]}");
      // }
    }
  }
}

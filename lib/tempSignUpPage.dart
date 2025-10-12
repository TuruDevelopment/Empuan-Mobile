import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:tumpuan/accountCred.dart';
import 'package:tumpuan/genderVerif.dart';
import 'package:tumpuan/screens/takePhoto.dart';
import 'package:tumpuan/signUp/bridgetoQ.dart';
import 'package:tumpuan/signUp/intro.dart';
import 'package:tumpuan/start_page.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class tempSignUpPage extends StatefulWidget {
  const tempSignUpPage({Key? key}) : super(key: key);

  @override
  State<tempSignUpPage> createState() => _tempSignUpPageState();
}

double progressPercentage = 0.33;

class _tempSignUpPageState extends State<tempSignUpPage> with TickerProviderStateMixin{
  File? _image;

  late PageController _pageViewController = PageController();
  late TabController _tabController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }

  final String name = '';
  final String dob = '';
  final String email = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dateInputController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isImageUploaded = _image != null;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              AppBar(
              toolbarHeight: 70,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () {
                    _showCloseDialog(context);
                  },
                    icon: const Icon(
                    Icons.close,
                    color: Colors.black,
                  ),
                 )
              ],
              title: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Tumpuan',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                  fontFamily: 'Brodies',
                  color: Color.fromRGBO(251, 111, 146, 1),
                  fontSize: 30,
                  ),
                ),
              ),
            ),
              SizedBox(height: 10,),
              Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: LinearPercentIndicator(
                    lineHeight: 3.0,
                    percent: _currentProgressPercent(_currentPageIndex, progressPercentage),
                  
                    backgroundColor: Colors.grey,
                    progressColor: AppColors.pink1,
                    ),
              )
            ],
          ),
          Positioned.fill(
            top: 175,
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageViewController,
              onPageChanged: _handlePageViewChanged,
              children: [
                Center(
                  child: Column(
                    children: [
                    Padding(
                    padding: EdgeInsets.only(left: 25.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Personal Detail',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w900,
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        buildTextField(
                        controller: firstNameController,
                        hintText: 'First and Middle Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first and middle name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      buildTextField(
                        controller: dateInputController,
                        hintText: 'Birth Date',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your birth date';
                          }
                          return null;
                        },
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
                      const SizedBox(height: 20),
                      buildTextField(
                        controller: emailController,
                        hintText: 'Email',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(251, 111, 146, 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ],
                    )
                  )
                  ],
                  )
                ),
                Center(
                  child: Column(
                    children: [
                      const Padding(
                      padding: EdgeInsets.only(left: 25.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Gender Verification',
                          style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          ),
                        ),
                      ),
                      ),
                    const SizedBox(height: 20),
                    _image == null
                    ? IconButton(
                        icon: Image.asset('images/ktp.png'),
                        iconSize: 300,
                        onPressed: () async {
                          final pickedImage = await Navigator.push<File?>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageSelectionPage(),
                            ),
                          );
                          setState(() {
                            _image = pickedImage ?? File('images/ktp.png');
                          });
                        },
                      )
                    : Container(
                        height: 400,
                        width: 300,
                        child: Image.file(_image!),
                      ),
                      const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.only(left: 0),
                       child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Make sure to take a clear picture of your ID',
                          style: TextStyle(fontFamily: 'Satoshi', fontSize: 12),
                        ),
                     ),
                    ),
                    const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(251, 111, 146, 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: isImageUploaded
                              ? const Color.fromRGBO(251, 111, 146, 1)
                              : Colors
                                  .grey, // Disable button when no image is uploaded
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ]
                  ),
                  ]),
                ),
                Center(
                  child: Column(
                    children: [
                      const Padding(
                    padding: EdgeInsets.only(left: 25.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Account Credentials',
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.bold,
                            fontSize: 25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children:[
                      buildTextField(
                        controller: usernameController,
                        hintText: 'Username',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
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
                      ),
                      ]
                    )
                  ),
                  const SizedBox(height: 200),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Container(
                          width: 100,
                          // padding: EdgeInsets.only(left: 0),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(251, 111, 146, 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(251, 111, 146, 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ],
            )
          ),
          Positioned(
          bottom: 125,
          child: PageIndicator(
            tabController: _tabController,
            currentPageIndex: _currentPageIndex,
            onUpdateCurrentPageIndex: _updateCurrentPageIndex,
            formKey: _formKey,
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            dateInputController: dateInputController,
            emailController: emailController,
            usernameController: usernameController,
            passwordController: passwordController,
            isImageUploaded: isImageUploaded,
            // isOnDesktopAndWeb: _isOnDesktopAndWeb,
          ),
        )
        ],
      ),
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    _tabController.index = currentPageIndex;
    setState(() {
      _currentPageIndex = currentPageIndex;
    });
  }

  void _updateCurrentPageIndex(int index) {
    _tabController.index = index;
    _pageViewController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> RegistrationUser(var firstNameController, var dateInputController, var emailController, var usernameController, var passwordController) async {
    final name = firstNameController.text;
    final dob = dateInputController.text;
    final email = emailController.text;
    final username = usernameController.text;
    final password = passwordController.text;

    print('Name: $name');
    print('DOB: $dob');
    print('Email: $email');

    final token = Uuid().v4();

    final body = {
      "name": name,
      "dob": dob,
      "email": email,
      "username": username,
      "password": password,
      "gender": 1,
      "token": token,
    };

    final url = 'http://10.0.2.2:8000/api/users';
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
    });

    print(response.statusCode);
    print(response.body);
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    Function()? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          suffixIcon:
              hintText == 'Birth Date' ? Icon(Icons.calendar_month) : null,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
        onTap: onTap,
      ),
    );
  }
}

_currentProgressPercent(var currentPageIndex, var progressPercentage) {
  if(currentPageIndex == 2){
    return progressPercentage = 1.0;
  } else if(currentPageIndex == 0){
    return progressPercentage = 0.33;
  }

  return (progressPercentage + 0.33);
}

class PageIndicator extends StatelessWidget {
  _tempSignUpPageState tempSignUpPage = new _tempSignUpPageState();

  PageIndicator({
    super.key,
    required this.tabController,
    required this.currentPageIndex,
    required this.onUpdateCurrentPageIndex,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.dateInputController,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    required this.isImageUploaded,
  });

  final int currentPageIndex;
  final TabController tabController;
  final void Function(int) onUpdateCurrentPageIndex;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController firstNameController;
  TextEditingController lastNameController;
  TextEditingController dateInputController;
  TextEditingController emailController;
  TextEditingController usernameController;
  TextEditingController passwordController;
  bool isImageUploaded;
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children:[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
            padding: const EdgeInsets.only(right: 7.0),
            child: Visibility(
              visible: visibleButton(currentPageIndex, _isVisible),
              child: SizedBox(
                width: 125,
                child: FilledButton(
                  onPressed: () {
                    if (currentPageIndex == 0) {
                    return;
                   }
                   onUpdateCurrentPageIndex(currentPageIndex - 1);
                  },
                  style: ButtonStyle(
                       backgroundColor: MaterialStateProperty.all(
                      const Color.fromRGBO(251, 111, 146, 1))),
                  child: const Text(
                  'Back',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    ),
                ),
                ),
            ),
            )
        ),
        Padding(
            padding: const EdgeInsets.only(right: 7.0),
            child: SizedBox(
                width: 125,
                child: FilledButton(
                  onPressed: () {
                  if (currentPageIndex == 0) {
                    if (formKey.currentState!.validate() == false) {
                      return;
                    }
                    print(firstNameController.text);
                    print(lastNameController.text);
                    print(dateInputController.text);
                    print(emailController.text);
                  }              
                  if (currentPageIndex == 1) {
                    if (isImageUploaded == false) {
                      return;
                    }
                  }   
                  if (currentPageIndex == 2) {
                    if (formKey.currentState!.validate()){
                      tempSignUpPage.RegistrationUser(firstNameController, dateInputController, emailController, usernameController, passwordController);
                      Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => BridgetoQ(username: usernameController.text, password: passwordController.text,)));
                    }

                    return;
                  }

                  onUpdateCurrentPageIndex(currentPageIndex + 1);
                  },
                  style: ButtonStyle(
                       backgroundColor: MaterialStateProperty.all(
                      const Color.fromRGBO(251, 111, 146, 1))),
                  child: Text(
                  'Save & Next',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    ),
                ),
                ),
            ),
        ),
        ],
        ),
        ]
      )
    );
  }
}

visibleButton(var currentPageIndex, bool isVisible) {
  if(currentPageIndex == 0){
    return isVisible = false;
  }
  return true;
}

Future<void> _showCloseDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Image(image: AssetImage('images/cancelRegist.png')),
            ],
          ),
        ),
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
            child: const Text('Yes', style: TextStyle(color: AppColors.pink1)),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const StartPage()),
              );
            },
          ),
        ],
      );
    },
  );
}

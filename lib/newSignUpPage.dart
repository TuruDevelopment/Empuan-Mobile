// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:percent_indicator/percent_indicator.dart';
// import 'package:tumpuan/genderVerif.dart';
// import 'package:tumpuan/start_page.dart';
// import 'package:tumpuan/styles/style.dart';

// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});

//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   @override
//   TextEditingController dateInputController = TextEditingController();
//   bool _validate = false;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
//       // ignore: prefer_const_constructors
//       body: SingleChildScrollView(
//         child: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 10),
//                 AppBar(
//                   toolbarHeight: 70,
//                   elevation: 0,
//                   backgroundColor: Colors.transparent,
//                   automaticallyImplyLeading: false,
//                   actions: [
//                     IconButton(
//                         onPressed: () {
//                           _showCloseDialog(context);
//                         },
//                         icon: const Icon(
//                           Icons.close,
//                           color: Colors.black,
//                         ))
//                   ],
//                   title: const Align(
//                     alignment: Alignment.bottomLeft,
//                     child: Text(
//                       'Tumpuan',
//                       textAlign: TextAlign.left,
//                       style: TextStyle(
//                           fontFamily: 'Brodies',
//                           color: Color.fromRGBO(251, 111, 146, 1),
//                           fontSize: 40),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 // Padding(
//                 //   padding: const EdgeInsets.only(left: 25.0),
//                 //   child: Align(
//                 //       alignment: Alignment.bottomLeft,
//                 //       child:
//                 //           Image(image: AssetImage('images/progressbar3.png'))),
//                 // ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: LinearPercentIndicator(
//                     // width: ,
//                     lineHeight: 3.0,
//                     percent: 0.33,
//                     backgroundColor: Colors.grey,
//                     progressColor: AppColors.pink1,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Padding(
//                   padding: EdgeInsets.only(left: 25.0),
//                   child: Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       'Personal Detail',
//                       style: TextStyle(
//                           fontFamily: 'Satoshi',
//                           fontWeight: FontWeight.bold,
//                           fontSize: 25),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: Container(
//                     decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         border: Border.all(color: Colors.black),
//                         borderRadius: BorderRadius.circular(12)),
//                     child: const Padding(
//                       padding: EdgeInsets.only(left: 20.0),
//                       child: TextField(
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           hintText: 'First and Middle Name',
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(
//                   height: 20,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: Container(
//                     decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         border: Border.all(color: Colors.black),
//                         borderRadius: BorderRadius.circular(12)),
//                     child: const Padding(
//                       padding: EdgeInsets.only(left: 20.0),
//                       child: TextField(
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           hintText: 'Last Name',
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(
//                   height: 20,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: Container(
//                     decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         border: Border.all(color: Colors.black),
//                         borderRadius: BorderRadius.circular(12)),
//                     child: Padding(
//                       padding: const EdgeInsets.only(left: 20.0),
//                       child: TextFormField(
//                         decoration: const InputDecoration(
//                             hintText: 'Birth Date',
//                             suffixIcon: Icon(Icons.calendar_month)),
//                         controller: dateInputController,
//                         readOnly: true,
//                         onTap: () async {
//                           DateTime? pickedDate = await showDatePicker(
//                               context: context,
//                               initialDate: DateTime.now(),
//                               firstDate: DateTime(1950),
//                               lastDate: DateTime(2050));

//                           if (pickedDate != null) {
//                             dateInputController.text =
//                                 DateFormat('dd MMMM yyyy').format(pickedDate);
//                           }
//                         },
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(
//                   height: 20,
//                 ),

//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                   child: Container(
//                     decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         border: Border.all(color: Colors.black),
//                         borderRadius: BorderRadius.circular(12)),
//                     child: const Padding(
//                       padding: EdgeInsets.only(left: 20.0),
//                       child: TextField(
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           hintText: 'Address',
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 //password
//                 // Padding(
//                 //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                 //   child: Container(
//                 //     decoration: BoxDecoration(
//                 //         color: Colors.grey[200],
//                 //         border: Border.all(color: Colors.black),
//                 //         borderRadius: BorderRadius.circular(12)),
//                 //     child: Padding(
//                 //       padding: const EdgeInsets.only(left: 20.0),
//                 //       child: TextField(
//                 //         obscureText: true,
//                 //         decoration: InputDecoration(
//                 //             border: InputBorder.none,
//                 //             hintText: 'Password',
//                 //             suffixIcon: Icon(Icons.remove_red_eye_outlined)),
//                 //       ),
//                 //     ),
//                 //   ),
//                 // ),
//                 // SizedBox(
//                 //   height: 20,
//                 // ),
//                 // Padding(
//                 //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
//                 //   child: Container(
//                 //     decoration: BoxDecoration(
//                 //         color: Colors.grey[200],
//                 //         border: Border.all(color: Colors.black),
//                 //         borderRadius: BorderRadius.circular(12)),
//                 //     child: Padding(
//                 //       padding: const EdgeInsets.only(left: 20, right: 10),
//                 //       child: DropdownButtonFormField<String>(
//                 //         decoration: const InputDecoration(),
//                 //         hint: const Text('Gender'),
//                 //         items: <String>['Female', 'Male'].map((String value) {
//                 //           return DropdownMenuItem<String>(
//                 //             value: value,
//                 //             child: Text(value),
//                 //           );
//                 //         }).toList(),
//                 //         onChanged: (_) {},
//                 //       ),
//                 //     ),
//                 //   ),
//                 // ),

//                 const SizedBox(
//                   height: 20,
//                 ),
//                 //sign in button
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 25),
//                   child: Container(
//                     width: 100,
//                     // padding: EdgeInsets.only(left: 0),
//                     decoration: BoxDecoration(
//                       color: const Color.fromRGBO(251, 111, 146, 1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Center(
//                       child: TextButton(
//                         child: const Text(
//                           'Save & Next',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                         onPressed: () {
//                           Navigator.of(context).push(MaterialPageRoute(
//                               builder: (context) => const GenderVerifPage()));
//                         },
//                       ),
//                     ),
//                   ),
//                 ),

//                 // SizedBox(
//                 //   height: 15,
//                 // ),
//                 // // register button
//                 // Row(
//                 //   mainAxisAlignment: MainAxisAlignment.center,
//                 //   children: [
//                 //     Text(
//                 //       'Have An Account?',
//                 //       style: TextStyle(fontWeight: FontWeight.bold),
//                 //     ),
//                 //     TextButton(
//                 //       child: const Text(
//                 //         'Login Here',
//                 //         style: TextStyle(
//                 //             color: Color.fromRGBO(251, 111, 146, 1),
//                 //             fontWeight: FontWeight.bold),
//                 //       ),
//                 //       onPressed: () {
//                 //         Navigator.of(context).pushReplacement(MaterialPageRoute(
//                 //             builder: (context) => LoginPage()));
//                 //       },
//                 //     )
//                 //   ],
//                 // ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// Future<void> _showCloseDialog(BuildContext context) async {
//   return showDialog<void>(
//     context: context,
//     barrierDismissible: false, // user must tap button!
//     builder: (BuildContext context) {
//       return AlertDialog(
//         // title: Text(
//         //   'Canceling Registration?',
//         //   style: TextStyle(fontFamily: 'Satoshi'),
//         // ),
//         content: const SingleChildScrollView(
//           child: ListBody(
//             children: <Widget>[
//               Image(image: AssetImage('images/cancelRegist.png')),
//             ],
//           ),
//         ),
//         actions: <Widget>[
//           TextButton(
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: AppColors.pink1),
//             ),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//           TextButton(
//             child: const Text('Yes', style: TextStyle(color: AppColors.pink1)),
//             onPressed: () {
//               Navigator.of(context).pushReplacement(
//                 MaterialPageRoute(builder: (context) => const StartPage()),
//               );
//             },
//           ),
//         ],
//       );
//     },
//   );
// }

// class LabeledCheckboxExample extends StatelessWidget {
//   final String sentences;
//   final bool? value;
//   final ValueChanged<bool?>? onChanged;

//   const LabeledCheckboxExample({
//     required this.sentences,
//     required this.value,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//               color: AppColors.bg1, borderRadius: BorderRadius.circular(10)),
//           child: CheckboxListTile(
//             // controlAffinity: ListTileControlAffinity.leading,
//             // contentPadding: EdgeInsets.zero,
//             dense: true,
//             title: Text(
//               sentences,
//               style: const TextStyle(
//                   fontSize: 16.0, color: Colors.black, fontFamily: 'Satoshi'),
//             ),
//             value: value,
//             onChanged: onChanged,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20.0), // Optionally
//               side: const BorderSide(color: Colors.pink),
//             ),
//             activeColor: const Color.fromRGBO(251, 111, 146, 1),
//             checkboxShape: CircleBorder(),
//           ),
//         ),
//         SizedBox(
//           height: 10,
//         )
//       ],
//     );
//   }
// }

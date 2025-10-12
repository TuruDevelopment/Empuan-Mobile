import 'package:flutter/material.dart';
import 'package:tumpuan/components/contactBox.dart';
import 'package:tumpuan/styles/style.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({
    super.key,
    required this.username,
    required this.profilePicture,
    // required this.userID,
  });

  final String username;
  // final String userID;
  final String profilePicture;

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late String username;
  // late String userID;
  late String profilePicture;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Edit Profile',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.check,
              color: AppColors.pink1,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text(
              //   'Edit Profile',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //       fontFamily: 'Satoshi',
              //       fontWeight: FontWeight.bold,
              //       fontSize: 25),
              // ),
            ],
          ),
          SizedBox(height: 10),
          CircleAvatar(
            backgroundImage: AssetImage(widget.profilePicture),
            radius: 40,
          ),
          SizedBox(height: 20),
          Text('Change Profile Picture'),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              // width: 300,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Username',
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.bold,
                            fontSize: 17),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            // hintText: widget.userID,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Change of username will be in effect at least 1 day',
                        style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              // width: 300,
              child: Column(
                children: [
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.start,
                  //   children: [
                  //     Text(
                  //       'User ID',
                  //       style: TextStyle(
                  //           fontFamily: 'Satoshi',
                  //           fontWeight: FontWeight.bold,
                  //           fontSize: 17),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(
                  //   height: 5,
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 0),
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey[200],
                  //       border: Border.all(color: Colors.black),
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     child: Padding(
                  //       padding: const EdgeInsets.only(left: 20.0),
                  //       child: TextField(
                  //         readOnly: true,
                  //         decoration: InputDecoration(
                  //           border: InputBorder.none,
                  //           hintText: widget.userID,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

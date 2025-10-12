import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:tumpuan/components/contactBox.dart';
import 'package:tumpuan/screens/addContact.dart';
import 'package:tumpuan/services/auth_service.dart';

class PanggilPuan extends StatefulWidget {
  const PanggilPuan({super.key});

  @override
  State<PanggilPuan> createState() {
    return _PanggilPuanState();
  }
}

class _PanggilPuanState extends State<PanggilPuan> {
  bool isLoading = true;

  void initState() {
    super.initState();
    getData();
  }

  List<dynamic> dataMore = [];

  @override
  Widget build(BuildContext context) {
    print(dataMore);
    final dataContact = [
      ['Ayah', 'images/profileDefault.jpg', '082122504942', 'Relation'],
      ['Ibu', 'images/profileDefault.jpg', '0000000000', ''],
      ['Ayah2', 'images/profileDefault.jpg', '082122504942', ''],
      ['Ayah3', 'images/profileDefault.jpg', '082122504942', ''],
      ['Ayah4', 'images/profileDefault.jpg', '082122504942', ''],
      ['Ayah5', 'images/profileDefault.jpg', '082122504942', ''],
      ['Ayah6', 'images/profileDefault.jpg', '082122504942', ''],
      ['Ayah7', 'images/profileDefault.jpg', '082122504942', ''],
    ];

    final datanya = ['Ayah', 'images/profileDefault.jpg', '082122504942'];

    Widget addButton = Container(
      height: 25,
      // color: Colors.amber,
      child: TextButton(
        child: Text(
          "Add Contact",
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => AddContact(
                onContactAdded: () {
                  getData(); // Memperbarui data setelah kontak ditambahkan
                },
              ),
            ),
          );
        },
      ),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 130, vertical: 320),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          addButton,
          Divider(
            color: Colors.white,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      backgroundColor: Colors.black,
    );

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
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.grey,
            ),
            onPressed: () {
              // do something
            },
          )
        ],
      ),
      body: Visibility(
        visible: isLoading,
        child: Center(child: CircularProgressIndicator()),
        replacement: RefreshIndicator(
          onRefresh: getData,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 15),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Fake Contacts',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 15),
                // ContactBox(
                //     name: 'Ayah',
                //     image: 'images/profileDefault.jpg',
                //     number: '082122504942'),
                getDataContact(dataMore, getData),
                SizedBox(height: 10),
                IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddContact(
                            onContactAdded: () {
                              getData(); // Memperbarui data setelah kontak ditambahkan
                            },
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.add_circle,
                      size: 35,
                    )),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url = 'http://10.0.2.2:8000/api/kontakpalsus';
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
    }

    setState(() {
      isLoading = false;
    });
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }
}

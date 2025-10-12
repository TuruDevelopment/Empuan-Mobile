import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:tumpuan/components/cardMore.dart';
import 'package:tumpuan/components/headerMore.dart';
import 'package:tumpuan/components/middleBarMore.dart';
import 'package:tumpuan/components/searchCard.dart';
import 'package:tumpuan/screens/takePhoto.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;

class More extends StatefulWidget {
  const More({super.key});

  @override
  State<More> createState() {
    return _MoreState();
  }
}


class _MoreState extends State<More> {
  final ScrollController _scrollController = ScrollController();
  // late String? username;
  String? username;
  bool isLoading = true;
  void initState() {
    super.initState();
    getData();
    getUserData();
  }

  List<dynamic> dataMore = [
    // [
    //   'author',
    //   'images/profilePict.png',
    //   'images/suaraPuanImg.png',
    //   'date',
    //   'teks',
    //   'idPost',
    //   '1',
    //   '2'
    // ],
    // [
    //   'author2',
    //   'images/profilePict.png',
    //   'images/suaraPuanImg.png',
    //   'date2',
    //   'teks2',
    //   'idPost2',
    //   '3',
    //   '4'
    // ],
    // [
    //   'author2',
    //   'images/profilePict.png',
    //   '',
    //   'date2',
    //   'teks2',
    //   'idPost2',
    //   '3',
    //   '4'
    // ],
  ];

  // List<String> dataUser = [
  //   // 'author',
  //   // 'images/profilePict.png',
  //   // 'idPost'
  // ];

  late List<String> dataUser;

  // late String? username;

  TextEditingController threadNameController = TextEditingController();
  File? _image;

  @override
  Widget build(BuildContext context) {
    print(dataMore);
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Visibility(
        visible: isLoading,
        child: Center(child: CircularProgressIndicator()),
        replacement: RefreshIndicator(
          onRefresh: getData,
          child: SafeArea(
            bottom: false,
            child: ListView(
              controller: _scrollController,
              children: [
                // SearchCard(),
                if (username != null)
                  HeaderMore(
                    username: username != null
                        ? username!
                        : '', // Gunakan username ?? '' untuk memastikan nilai tidak null
                    img: dataUser.isNotEmpty
                        ? dataUser[1]
                        : 'images/profilePict.png',
                  ),

                StickyHeader(
                  controller: _scrollController,
                  header: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7.0),
                                  child: TextField(
                                      controller: threadNameController,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Write your Thoughts',
                                      )),
                                )),
                          ),
                          IconButton(
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
                              icon: _image != null
                                  ? Icon(Icons.photo, color: Colors.green)
                                  : Icon(Icons.add_photo_alternate,
                                      color: Colors.grey)),
                          SizedBox(
                            width: 5,
                          ),
                          ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(AppColors.pink1)),
                            onPressed: () {
                              submitData(imageFile: null);
                              getData();
                            },
                            child: Text('Post'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Card(
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(0),
                  //     child: Row(
                  //       children: [
                  //         MenuCard(text: "Italy", color: Colors.orange),
                  //         // MenuCard(text: "France", color: Colors.pink)
                  //         // TextField(
                  //         //     decoration: InputDecoration(
                  //         //   border: InputBorder.none,
                  //         //   hintText: 'Username',
                  //         // ))
                  //         // Card(
                  //         //   child: Padding(
                  //         //     padding: const EdgeInsets.all(
                  //         //         8.0), // Add padding here as well
                  //         //     child: TextField(),
                  //         //   ),
                  //         // )
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  content: getDataMore(dataMore),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

Future<void> submitData({required File? imageFile}) async {
    final threadName = threadNameController.text;
    final threadDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String? imagePath;

    final url = 'http://10.0.2.2:8000/api/ruangPuans';
    final uri = Uri.parse(url);

    try {
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] =
          '${AuthService.token}'; // Add authorization header

      if (imageFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('media', imageFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        imagePath =
            responseData['media']; // Assuming the API returns the file path
      } else {
        print('Error posting data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting data: $e');
    }

    final body = {
      "threadName": threadName,
      "threadDate": threadDate,
      "like": 0
    };

    final response = await http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      'Authorization': '${AuthService.token}'
    });

    print('hasil post ruang puan ${response.statusCode}');
    print(body);
    print(response.body);
    threadNameController.clear();

    getData();
  }



  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
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
    }

    setState(() {
      isLoading = false;
    });
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }

  Future<List<String>> getCurrentUser() async {
    final url = 'http://10.0.2.2:8000/api/users/current';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['data'] ?? [];
      if (result.isNotEmpty &&
          result.containsKey('name') &&
          result.containsKey('id')) {
        final username = result['name'].toString();
        final userId = result['id'].toString();
        final profilePicture =
            'images/profilePict.png'; // or the default value from API
        return [username, profilePicture, userId];
      }
    }
    return [];
  }

  Future<void> getUserData() async {
    final userData = await getCurrentUser();
    if (userData.isNotEmpty) {
      setState(() {
        username = userData[0];
        dataUser = userData;
      });
    }
  }
}



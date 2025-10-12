import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:tumpuan/components/commentBox.dart';
import 'package:tumpuan/components/searchCard.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;

class Comment extends StatefulWidget {
  const Comment({Key? key, required this.idRuangPuan}) : super(key: key);

  final int idRuangPuan;

  @override
  State<Comment> createState() {
    return _CommentState();
  }
}

class _CommentState extends State<Comment> {
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;

  TextEditingController _commentController = TextEditingController();

  void initState() {
    super.initState();
    getData();
  }
  // final dataComment = [
  //   ['author', 'images/profilePict.png', 'date', 'teks', 'idPost', '1', '2'],
  //   [
  //     'author2',
  //     'images/profilePict.png',
  //     'date2',
  //     'teks2',
  //     'idPost2',
  //     '3',
  //     '4'
  //   ],
  //   [
  //     'author2',
  //     'images/profilePict.png',
  //     'date2',
  //     'teks2',
  //     'idPost2',
  //     '3',
  //     '4'
  //   ],
  // ];

  List<dynamic> dataComment = [];

  final dataUser = ['Nixonnn', 'images/profilePict.png', '12345'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Comments',
          style: TextStyle(color: Colors.black),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    getDataComment(dataComment),
                  ],
                ),
              ),
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7.0),
                            child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Write your Comment',
                                )),
                          )),
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(AppColors.pink1)),
                      onPressed: () {
                        submitComment();
                      },
                      child: Text('Post'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<String?> getUsernameById(String userId) async {
    final url = 'http://10.0.2.2:8000/api/users/$userId';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['data'];
      if (result != null && result.containsKey('name')) {
        return result['name'].toString();
      }
    }

    return null;
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url =
        'http://10.0.2.2:8000/api/ruangPuans/${widget.idRuangPuan}/commentRuangPuans';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      print('items kita' + json['data'].toString());
      final result = json['data'] ?? [] as List;
      setState(() {
        dataComment = result;
      });
    }

    setState(() {
      isLoading = false;
    });
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }

  Future<String?> getCurrentUser() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url = 'http://10.0.2.2:8000/api/users/current';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      print('items kita' + json['data'].toString());
      final result = json['data'] ?? [] as List;
      // setState(() {
      //   dataCurrentUser = result;
      // });

      if (result != null && result.containsKey('name')) {
        final name = result['name'].toString();
        setState(() {
          isLoading = false;
        });
        return name;
      }
    }

    setState(() {
      isLoading = false;
    });
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }

  Future<void> submitComment() async {
    final comment = _commentController.text;
    final dop = DateFormat('yyyy-MM-dd').format(DateTime.now()).toString();

    print(comment + ' - ' + dop);

    final body = {
      'comment': comment,
      'dop': dop,
    };

    final url =
        'http://10.0.2.2:8000/api/ruangPuans/${widget.idRuangPuan}/commentRuangPuans';
    print('url: ' + url);
    final uri = Uri.parse(url);

    // Dapatkan username dari getCurrentUser
    String? username = await getCurrentUser();
    if (username == null) {
      // Gagal mendapatkan username
      print('Failed to get username');
      return;
    }

    final response = await http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      'Authorization': '${AuthService.token}'
    });

    if (response.statusCode == 200) {
      setState(() {
        dataComment.add({
          'comment': comment,
          'dop': dop,
          'user_id': username,
          'profilePict': 'images/profileDefault.jpg'
        });
        _commentController.clear();
      });
    } else {
      print('Error submitting comment: ${response.statusCode}');
      print(response.body);
    }
  }
  // Future<void> submitData() async {
  //   final name = nameController.text;
  //   final number = numberController.text;
  //   final relation = relationController.text;
  //   final body = {
  //     'name': name,
  //     'phoneNumber': number,
  //     'relation': relation,
  //   };

  //   final url = "http://10.0.2.2:8000/api/kontakpalsus";
  //   final uri = Uri.parse(url);
  //   final response = await http.post(uri, body: jsonEncode(body), headers: {
  //     'Content-Type': 'application/json',
  //     'Authorization': '${AuthService.token}'
  //   });

  //   print(response.statusCode);
  //   print(response.body);
  // }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

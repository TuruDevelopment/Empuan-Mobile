import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tumpuan/components/callView.dart';
import 'package:tumpuan/components/editContact.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;

Widget getDataComment(List<dynamic> dataComment) {
  // String username;
  // String profilePict;
  // String date;
  // String teks;
  // String idPost;
  // String likeCount;
  // String commentCount;

  String user_id;
  String comment;
  String dop;
  // String like;
  int ruangpuan_id;

  List<Widget> dataCommentBoxes = [];
  for (var i = 0; i < dataComment.length; i++) {
    // username = dataComment[i][0];
    // profilePict = dataComment[i][1];
    // date = dataComment[i][2];
    // teks = dataComment[i][3];
    // idPost = dataComment[i][4];
    // likeCount = dataComment[i][5];
    // commentCount = dataComment[i][6];

    user_id = dataComment[i]['user_id'].toString();
    comment = dataComment[i]['comment'].toString();
    dop = dataComment[i]['dop'].toString();
    // like = dataComment[i]['like'].toString();
    ruangpuan_id = dataComment[i]['ruangpuan_id'];

    dataCommentBoxes.add(CommentBox(
      // username: username,
      // profilePict: profilePict,
      // date: date,
      // teks: teks,
      // idPost: idPost,
      // likeCount: likeCount,
      // commentCount: commentCount,

      user_id: user_id,
      comment: comment,
      dop: dop,
      // like: like,
      ruangpuan_id: ruangpuan_id,
    ));
    dataCommentBoxes.add(SizedBox(height: 10));
  }
  return Column(
    children: dataCommentBoxes,
  );
}

class CommentBox extends StatelessWidget {
  CommentBox(
      {Key? key,
      required this.user_id,
      required this.comment,
      required this.dop,
      required this.ruangpuan_id})
      : super(key: key);

  final String user_id;
  final String comment;
  final String dop;
  final int ruangpuan_id;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getUsernameById(user_id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Menampilkan loading spinner selama proses penungguan
        } else if (snapshot.hasError) {
          return Text(
              'Error: ${snapshot.error}'); // Menampilkan pesan error jika terjadi kesalahan
        } else {
          final username = snapshot.data ??
              'Unknown User'; // Mendapatkan hasil dari fungsi getUsernameById
          return Center(
            child: Container(
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      child: Row(
                        children: [
                          SizedBox(width: 10),
                          CircleAvatar(
                            backgroundImage:
                                AssetImage('images/profilePict.png'),
                            radius: 30,
                          ),
                          SizedBox(width: 20),
                          Container(
                            width: 270,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      username,
                                      style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    Text(
                                      dop,
                                      style: TextStyle(
                                          fontFamily: 'Satoshi', fontSize: 15),
                                    )
                                  ],
                                ),
                                Container(
                                  width: 270,
                                  child: Text(
                                    comment,
                                    style: TextStyle(
                                        fontFamily: 'Satoshi', fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        child: Row(
                          children: [
                            SizedBox(width: 5),
                          ],
                        ),
                      ),
                      SizedBox(width: 15),
                      Container(
                        child: Row(
                          children: [
                            Icon(Icons.favorite_border),
                            SizedBox(width: 5),
                            Text('10')
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          );
        }
      },
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
}

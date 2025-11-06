import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
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
  int? ruangpuan_id;

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
    ruangpuan_id = dataComment[i]['ruangpuan_id'] as int?;

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
      this.ruangpuan_id})
      : super(key: key);

  final String user_id;
  final String comment;
  final String dop;
  final int? ruangpuan_id;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getUsernameById(user_id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'Error loading comment',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          );
        } else {
          final username = snapshot.data ?? 'Unknown User';
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundImage: AssetImage('images/profilePict.png'),
                      radius: 20,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              username,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dop,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        comment,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Future<String?> getUsernameById(String userId) async {
    final url = 'http://192.168.8.48:8000/api/users/$userId';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});

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

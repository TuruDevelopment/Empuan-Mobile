import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

Widget getDataComment(List<dynamic> dataComment) {
  String userName;
  String comment;
  String dop;
  int? ruangpuan_id;

  List<Widget> dataCommentBoxes = [];
  for (var i = 0; i < dataComment.length; i++) {
    // Get username from user object in comment response
    userName = dataComment[i]['user']?['name']?.toString() ?? 'Anonymous';
    comment = dataComment[i]['comment'].toString();
    dop = dataComment[i]['dop']?.toString() ??
        dataComment[i]['created_at']?.toString() ??
        '';
    ruangpuan_id = dataComment[i]['ruangpuan_id'] as int?;

    print('📝 Comment by $userName: $comment');

    dataCommentBoxes.add(CommentBox(
      userName: userName,
      comment: comment,
      dop: dop,
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
      required this.userName,
      required this.comment,
      required this.dop,
      this.ruangpuan_id})
      : super(key: key);

  final String userName;
  final String comment;
  final String dop;
  final int? ruangpuan_id;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
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
                        userName,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
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
                          fontFamily: 'Plus Jakarta Sans',
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
                    fontFamily: 'Plus Jakarta Sans',
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
}

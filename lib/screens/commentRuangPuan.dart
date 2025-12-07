import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/components/commentBox.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

import 'package:Empuan/config/api_config.dart';

class Comment extends StatefulWidget {
  const Comment({Key? key, required this.idRuangPuan}) : super(key: key);

  final int idRuangPuan;

  @override
  State<Comment> createState() {
    return _CommentState();
  }
}

class _CommentState extends State<Comment> {
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
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        title: Text(
          'Comments',
          style: TextStyle(
            fontFamily: 'Brodies',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surface,
              AppColors.background,
              AppColors.accent.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : dataComment.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                getDataComment(dataComment),
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
              ),
              _buildCommentInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: AppColors.accent.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Comments Yet',
              style: TextStyle(
                fontFamily: 'Brodies',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Be the first to share your thoughts!\nStart the conversation below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _commentController,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write your comment...',
                  hintStyle: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryVariant,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                if (_commentController.text.trim().isNotEmpty) {
                  submitComment();
                }
              },
              child: Row(
                children: [
                  Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Post',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url =
        '${ApiConfig.baseUrl}/ruang-puan/${widget.idRuangPuan}/comments';
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
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

  Future<Map<String, String>?> getCurrentUser() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url = '${ApiConfig.baseUrl}/me';
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      print('items kita' + json.toString());

      // API /me returns: {"user": {...}, "roles": [...]}
      final userData = json['user'];

      if (userData != null &&
          userData is Map &&
          userData.containsKey('name') &&
          userData.containsKey('id')) {
        final name = userData['name'].toString();
        final userId = userData['id'].toString();
        setState(() {
          isLoading = false;
        });
        return {'name': name, 'id': userId};
      }
    }

    setState(() {
      isLoading = false;
    });
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);

    return null;
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
        '${ApiConfig.baseUrl}/ruang-puan/${widget.idRuangPuan}/comments';
    print('url: ' + url);
    final uri = Uri.parse(url);

    // Dapatkan username dan user_id dari getCurrentUser
    Map<String, String>? userData = await getCurrentUser();
    if (userData == null) {
      // Gagal mendapatkan user data
      print('Failed to get user data');
      return;
    }

    final response = await http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AuthService.token}'
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Reload comments to get the new comment with user data from API
      await getData();
      _commentController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Comment posted successfully!',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('Error submitting comment: ${response.statusCode}');
      print(response.body);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Failed to post comment. Please try again.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
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

  //   final url = "http://192.168.1.7:8000/api/kontakpalsus";
  //   final uri = Uri.parse(url);
  //   final response = await http.post(uri, body: jsonEncode(body), headers: {
  //     'Content-Type': 'application/json',
  //     'Authorization': 'Bearer ${AuthService.token}'
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Empuan/components/bannerSuaraPuan.dart';
import 'package:Empuan/components/content_suaraPuan.dart'; // Added for getKategoriById
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';

import 'package:Empuan/config/api_config.dart';

class Comment {
  String text;
  String date;
  String userName;
  String userProfilePic;
  Comment(this.text, this.date, this.userName, this.userProfilePic);
}

class User {
  String username;
  String email;
  String password;
  String name;
  String dob;
  String gender;

  User({
    required this.username,
    required this.email,
    required this.password,
    required this.name,
    required this.dob,
    required this.gender,
  });
}

Widget getDataSuaraPuan(List<dynamic> dataSuaraPuan) {
  return Column(
    children: dataSuaraPuan.map((data) {
      final id = data['id'].toString();
      final title = data['title'].toString();
      final content = data['content'].toString();
      final media = data['media'].toString();
      final dop = data['dop'].toString();
      final kategori_id = data['kategori_id'].toString();
      final user_id = data['user_id'].toString();
      final video = data['video'].toString();

      return FutureBuilder<String?>(
        future: getKategoriById(kategori_id),
        builder: (context, snapshot) {
          final kategoriName = snapshot.data ?? '';
          return SuaraPuanBox(
              id: id,
              title: title,
              content: content,
              media: media,
              dop: dop,
              kategori_id: kategori_id,
              user_id: user_id,
              kategori_name: kategoriName,
              video: video);
        },
      );
    }).toList(),
  );
}

class IsiSuaraPuan extends StatefulWidget {
  final String id;
  final String title;
  final String content;
  final String media;
  final String dop;
  final String kategori_id;
  final String user_id;
  final String video;
  final String? kategori_name;

  const IsiSuaraPuan({
    Key? key,
    required this.id,
    required this.title,
    required this.content,
    required this.media,
    required this.dop,
    required this.kategori_id,
    required this.user_id,
    required this.video,
    this.kategori_name,
  }) : super(key: key);

  @override
  State<IsiSuaraPuan> createState() => _IsiSuaraPuanState();
}

class _IsiSuaraPuanState extends State<IsiSuaraPuan> {
  bool isLoading = true;
  String? kategoriName;

  void initState() {
    super.initState();
    getCurrentUser();
    getData();
    _loadKategoriName();
  }

  List<dynamic> dataComment = [];
  List<dynamic> dataCurrentUser = [];
  List<Comment> comments = [];

  TextEditingController _commentController = TextEditingController();
  TextEditingController _userNameController = TextEditingController();

  late String comment;
  late String dop;

  Future<void> _loadKategoriName() async {
    if (widget.kategori_name != null) {
      setState(() {
        kategoriName = widget.kategori_name;
      });
    } else {
      final name = await getKategoriById(widget.kategori_id);
      if (mounted) {
        setState(() {
          kategoriName = name;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: AppColors.primary.withOpacity(0.2),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image with gradient overlay + floating category chip
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: Image.network(
                    widget.media,
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 320,
                      color: AppColors.accent.withOpacity(0.3),
                      child: Icon(Icons.broken_image_rounded,
                          size: 64, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryVariant,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          kategoriName ?? widget.kategori_name ?? 'Loading...',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Brodies',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 26,
                          height: 1.25,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black45,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Meta info row (date, reading time)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  _metaChip(
                    icon: Icons.calendar_today_rounded,
                    label: widget.dop,
                  ),
                  const SizedBox(width: 10),
                  _metaChip(
                    icon: Icons.access_time_rounded,
                    label: '${_readingMinutes(widget.content)} min read',
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.0),
                      AppColors.accent.withOpacity(0.5),
                      AppColors.accent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Text(
                widget.content,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.normal,
                  color: AppColors.textPrimary,
                  fontSize: 15.5,
                  height: 1.7,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  int _readingMinutes(String text) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url = '${ApiConfig.baseUrl}/suara-puan/${widget.id}/comments';
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

    // Build comments list with user data from API response
    for (var data in dataComment) {
      var comment = data['comment'].toString();
      var dop = data['dop']?.toString() ?? data['created_at']?.toString() ?? '';
      var username = data['user']?['name']?.toString() ?? 'Anonymous';

      Comment newComment = Comment(
        comment,
        dop,
        username,
        'images/profileDefault.jpg',
      );

      setState(() {
        comments.add(newComment);
      });
    }
  }

  Future<String?> getCurrentUser() async {
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

    return null;
  }

  Future<void> submitComment() async {
    final comment = _commentController.text;
    final dop = DateFormat('yyyy-MM-dd').format(DateTime.now()).toString();

    print(comment + ' - ' + dop);

    final body = {
      'comment': comment,
      'dop': dop,
      // 'user_id': dataCurrentUser[0]['id'].toString(),
    };

    final id = widget.id;
    print(id);
    // submit data to the server
    final url = '${ApiConfig.baseUrl}/suara-puan/${widget.id}/comments';
    print('url: ' + url);
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AuthService.token}'
    });
    // showsuccess or fail message based on status
    print(response.statusCode);
    print(response.body);

    String? username = await getCurrentUser();
    if (username != null) {
      print('username: $username');

      // String username = AuthService.token.toString();
      // String username = widget.user_id;

      // print('username: ' + username);

      Comment newComment =
          Comment(comment, dop, username, 'images/profileDefault.jpg');

      setState(() {
        comments.add(newComment);
        _commentController.clear();
      });
    }

    // void _postComment() {
    //   String newCommentText = _commentController.text;
    //   String userName = _userNameController.text.isNotEmpty
    //       ? _userNameController.text
    //       : 'Anonymous';
    //   DateTime now = DateTime.now();
    //   Comment newComment =
    //       Comment(newCommentText, now, userName, 'images/profileDefault.jpg');
    //   setState(() {
    //     comments.add(newComment);
    //     _commentController.clear();
    //   });
    // }

    @override
    void dispose() {
      _commentController.dispose();
      _userNameController.dispose();
      super.dispose();
    }
  }
}

String getCategory(int id) {
  if (id == 1)
    return 'Lifestyle';
  else if (id == 2)
    return 'Business';
  else if (id == 3)
    return 'News';
  else if (id == 4)
    return 'Lifestyle and Personal Growth';
  else
    return '-';
}

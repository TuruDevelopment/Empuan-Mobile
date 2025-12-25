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
    final dataSuaraPuan = [
      [
        'Vivienne Westwood Menghasilkan Uang Rp 1,6 M Per Hari di Tahun Dia Meninggal',
        'images/business-1.jpg',
        '21 February 2024',
        'Business',
        'title2'
      ],
      [
        'Buttonscarves dan Kami. Rilis Koleksi Kolaborasi Tema Pemberdayaan Wanita',
        'images/lifestyle-1.jpg',
        '13 February 2023',
        'Lifestyle',
        'title'
      ],
      [
        'Polisi dan Psikolog Dampingi Anak Dayang Santi untuk Hilangkan Trauma',
        'images/news-1.jpeg',
        '9 February 2024',
        'News',
        'title3'
      ],
    ];

    final dataBannerSuara = dataSuaraPuan.sublist(0, 3);
    final PageController controller = PageController();
    int currentTab = 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        title: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Search...',
              hintStyle: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              suffixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primary,
              ),
            ),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image Container
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.2),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      widget.media,
                      width: MediaQuery.of(context).size.width,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Title and Meta Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Brodies',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                widget.dop,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryVariant,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            kategoriName ??
                                widget.kategori_name ??
                                'Loading...',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: AppColors.accent.withOpacity(0.2),
                  thickness: 1,
                ),
              ),

              SizedBox(height: 20),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.content,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.normal,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              SizedBox(height: 24),
            ],
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
    return 'Health';
  else
    return '-';
}

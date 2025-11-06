import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Empuan/components/bannerSuaraPuan.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:Empuan/components/content_suaraPuan.dart';
import 'package:video_player/video_player.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';

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
  }) : super(key: key);

  @override
  State<IsiSuaraPuan> createState() => _IsiSuaraPuanState();
}

class _IsiSuaraPuanState extends State<IsiSuaraPuan> {
  bool isLoading = true;

  late VideoPlayerController _videoController;
  void initState() {
    super.initState();
    getCurrentUser();
    getData();

    // uncomment yang ini klo mau pake link, tinggal ganti linknya
    // _videoController = VideoPlayerController.networkUrl(Uri.parse(
    //     'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'));

    // ..initialize().then((_) {
    //   // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
    //   setState(() {});
    // });

    // ini buat klo data videonya dari local
    _videoController = VideoPlayerController.asset(widget.video);
    _videoController.initialize().then((value) {
      setState(() {});
    });
    _videoController.setLooping(true);
  }

  List<dynamic> dataComment = [];
  List<dynamic> dataCurrentUser = [];
  List<Comment> comments = [];

  TextEditingController _commentController = TextEditingController();
  TextEditingController _userNameController = TextEditingController();

  late String comment;
  late String dop;

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
              fontFamily: 'Satoshi',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Search...',
              hintStyle: TextStyle(
                fontFamily: 'Satoshi',
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
            _videoController.pause();
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
                                  fontFamily: 'Satoshi',
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
                            getCategory(int.parse(widget.kategori_id)),
                            style: TextStyle(
                              fontFamily: 'Satoshi',
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
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.normal,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Video Player
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.1),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _videoController.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController.value.aspectRatio,
                            child: VideoPlayer(_videoController),
                          )
                        : Container(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // Video Controls
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _videoController.value.isPlaying
                              ? _videoController.pause()
                              : _videoController.play();
                        });
                      },
                      icon: Icon(
                        !_videoController.value.isPlaying ||
                                _videoController.value.isCompleted
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
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

              SizedBox(height: 24),

              // Recommendation Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.recommend_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Recommendation',
                      style: TextStyle(
                        fontFamily: 'Brodies',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Container(
                height: 230,
                child: PageView(
                  controller: controller,
                  onPageChanged: (index) {
                    setState(() {
                      currentTab = index;
                    });
                  },
                  children: [
                    for (var item in dataBannerSuara)
                      getDataBannerSuaraPuan(item)
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: AppColors.accent.withOpacity(0.2),
                  thickness: 1,
                ),
              ),

              SizedBox(height: 24),

              // Reaction Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary,
                                AppColors.primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.emoji_emotions_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'What do you think?',
                          style: TextStyle(
                            fontFamily: 'Brodies',
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildReactionButton('images/Happy.png'),
                        _buildReactionButton('images/Shock.png'),
                        _buildReactionButton('images/Sad.png'),
                        _buildReactionButton('images/Angry.png'),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: AppColors.accent.withOpacity(0.2),
                  thickness: 1,
                ),
              ),

              SizedBox(height: 24),

              // Comments Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.error,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.comment_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontFamily: 'Brodies',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.1),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: comments.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 48,
                                    color: AppColors.accent.withOpacity(0.5),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No comments yet',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Be the first to comment!',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 12,
                                      color: AppColors.textSecondary
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.all(16),
                              itemCount: comments.length,
                              separatorBuilder: (context, index) => Divider(
                                color: AppColors.accent.withOpacity(0.2),
                                height: 24,
                              ),
                              itemBuilder: (context, index) {
                                Comment comment = comments[index];
                                return Row(
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
                                          radius: 20,
                                          backgroundImage: AssetImage(
                                              comment.userProfilePic),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment.userName,
                                            style: TextStyle(
                                              fontFamily: 'Satoshi',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            comment.text,
                                            style: TextStyle(
                                              fontFamily: 'Satoshi',
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                              height: 1.4,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            comment.date
                                                .toString()
                                                .split('.')[0],
                                            style: TextStyle(
                                              fontFamily: 'Satoshi',
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    Divider(
                      color: AppColors.accent.withOpacity(0.2),
                      height: 1,
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _commentController,
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 14,
                                    color: AppColors.textSecondary
                                        .withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryVariant,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                submitComment();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Image.asset(
            imagePath,
            width: 40,
            height: 40,
          ),
        ),
      ),
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

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url =
        'http://192.168.8.48:8000/api/suarapuans/${widget.id}/commentpuans';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
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

    for (var data in dataComment) {
      var comment = data['comment'].toString();
      var dop = data['dop'].toString();

      String? username = await getUsernameById(data['user_id'].toString());
      if (username != null) {
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
  }

  Future<String?> getCurrentUser() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url = 'http://192.168.8.48:8000/api/users/current';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
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
    final url =
        'http://192.168.8.48:8000/api/suarapuans/${widget.id}/commentpuans';
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

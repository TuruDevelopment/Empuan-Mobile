import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tumpuan/components/bannerSuaraPuan.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:tumpuan/components/content_suaraPuan.dart';
import 'package:video_player/video_player.dart';
import 'package:tumpuan/services/auth_service.dart';

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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: TextField(
          decoration: InputDecoration(
              suffixIcon: Icon(Icons.search, color: Colors.black)),
        ),
        actions: <Widget>[],
        leading: IconButton(
          onPressed: () {
            _videoController.pause();
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.network(
                  widget.media,
                  width: MediaQuery.of(context).size.width,
                  height: 200,
                  fit: BoxFit.cover,
                )),
            Padding(
              padding: const EdgeInsets.only(top: 9),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                widget.title,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
            ),
            SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      Text(
                        widget.dop + " | ",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        getCategory(int.parse(widget.kategori_id)),
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(251, 111, 146, 1),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                '____________________________________________________',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                widget.content,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 4,
                child: _videoController.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      )
                    : Container(
                        // child: Text('gada'),
                        ),
              ),
            ),
            Container(
              child: Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
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
                          ? Icons.play_arrow
                          : Icons.pause,
                    ),
                  ),
                ],
              )),
            ),
            // SizedBox(
            //   height: 20,
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                '____________________________________________________',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommendation',
                    style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 20),
                  ),
                  // SizedBox(
                  //   height: 20,
                  //   width: 100,
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       Navigator.of(context).pushReplacement(MaterialPageRoute(
                  //           builder: (context) => IsiSuaraPuan(
                  //               id: 'id',
                  //               title: 'title',
                  //               content: 'content',
                  //               media: 'media',
                  //               dop: 'dop',
                  //               kategori_id: 'kategori_id',
                  //               user_id: 'user_id')));
                  //     },
                  //     style: ButtonStyle(
                  //       backgroundColor: MaterialStateProperty.all(
                  //           const Color.fromRGBO(251, 111, 146, 1)),
                  //       shape:
                  //           MaterialStateProperty.all<RoundedRectangleBorder>(
                  //               RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(18.0),
                  //       )),
                  //     ),
                  //     child: const Text(
                  //       'See More',
                  //       style: TextStyle(fontFamily: 'Satoshi'),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
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
                  for (var item in dataBannerSuara) getDataBannerSuaraPuan(item)
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                '____________________________________________________',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(
              height: 18,
            ),
            Text(
              'What do you think?                          ',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 21,
              ),
            ),
            SizedBox(
              height: 23,
            ),
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('images/Happy.png'),
                  SizedBox(width: 24, height: 24, child: null),
                  Image.asset('images/Shock.png'),
                  SizedBox(width: 24, height: 24, child: null),
                  Image.asset('images/Sad.png'),
                  SizedBox(width: 24, height: 24, child: null),
                  Image.asset('images/Angry.png'),
                ],
              ),
            ),
            SizedBox(
              height: 18,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                '____________________________________________________',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(
              height: 13,
            ),
            Text(
              'Comments                                       ',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 21,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        Comment comment = comments[index];
                        return ListTile(
                          leading: Padding(
                            padding: const EdgeInsets.only(left: 13),
                            child: CircleAvatar(
                              backgroundImage:
                                  AssetImage(comment.userProfilePic),
                            ),
                          ),
                          title: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Text(
                              comment.userName,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                              ),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
                                child: Text(
                                  comment.text,
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
                                child: Text(
                                  '${comment.date.toString().split('.')[0]}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 35,
                        right: 22.0,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () {
                              submitComment();
                            },
                          ),
                          SizedBox(height: 15),
                        ],
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.only(
                    //     left: 30,
                    //     right: 40,
                    //   ),
                    //   child: Row(
                    //     children: <Widget>[
                    //       Padding(
                    //         padding: const EdgeInsets.symmetric(horizontal: 0),
                    //         child: Text('Name : ',
                    //             style: TextStyle(
                    //               fontFamily: 'Satoshi',
                    //               fontWeight: FontWeight.bold,
                    //               fontSize: 16,
                    //             )),
                    //       ),
                    //       Expanded(
                    //         child: TextField(
                    //           controller: _userNameController,
                    //           decoration: InputDecoration(
                    //             hintText: 'Enter your display name...',
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
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
    final url = 'http://10.0.2.2:8000/api/suarapuans/${widget.id}/commentpuans';
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
      // 'user_id': dataCurrentUser[0]['id'].toString(),
    };

    final id = widget.id;
    print(id);
    // submit data to the server
    final url = 'http://10.0.2.2:8000/api/suarapuans/${widget.id}/commentpuans';
    print('url: ' + url);
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      'Authorization': '${AuthService.token}'
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

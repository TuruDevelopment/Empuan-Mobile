import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:Empuan/components/cardMore.dart';
import 'package:Empuan/screens/settings.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
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

  TextEditingController threadNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    print(dataMore);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.accent.withOpacity(0.1),
            ],
          ),
        ),
        child: Visibility(
          visible: isLoading,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
          replacement: RefreshIndicator(
            onRefresh: getData,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Modern App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.forum_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ruang Puan',
                                      style: TextStyle(
                                        fontFamily: 'Brodies',
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      'Share your thoughts',
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 13,
                                        color: AppColors.textSecondary
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Settings Button
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => Settings(
                                          username: username ?? 'User',
                                          profilePicture: dataUser.isNotEmpty
                                              ? dataUser[1]
                                              : 'images/profilePict.png',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.settings_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (username != null) ...[
                            const SizedBox(height: 16),
                            _buildUserInfoCard(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Modern Create Post Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildCreatePostCard(),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),

                  // Posts Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Recent Posts',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),

                  // Posts List
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: getDataMore(dataMore),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern User Info Card
  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage(
                  dataUser.isNotEmpty ? dataUser[1] : 'images/profilePict.png',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username ?? '',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Active Member',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: AppColors.secondary,
                ),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern Create Post Card
  Widget _buildCreatePostCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Create Post',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: threadNameController,
              maxLines: 3,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Share your thoughts...',
                hintStyle: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Post Button (Full Width)
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryVariant,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (threadNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.warning_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Please write something to post',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
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
                  return;
                }
                submitData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Post',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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

  Future<void> submitData() async {
    final threadName = threadNameController.text.trim();

    if (threadName.isEmpty) return;

    final threadDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final url = 'http://192.168.8.96:8000/api/ruangPuans';
    final uri = Uri.parse(url);

    final body = {
      "threadName": threadName,
      "threadDate": threadDate,
      "like": 0
    };

    try {
      final response = await http.post(
        uri,
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '${AuthService.token}'
        },
      );

      print('hasil post ruang puan ${response.statusCode}');
      print(body);
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear text field
        threadNameController.clear();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Post published successfully!',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
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

        // Refresh posts
        getData();
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Failed to post. Please try again.',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
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
    } catch (e) {
      print('Error submitting data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Network error. Please check your connection.',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                    ),
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

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url = 'http://192.168.8.96:8000/api/ruangPuans';
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
    final url = 'http://192.168.8.96:8000/api/users/current';
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

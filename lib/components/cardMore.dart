import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/screens/commentRuangPuan.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

Widget getDataMore(List<dynamic> dataMore) {
  String date;
  String teks;
  int idRuangPuan;
  String likeCount;
  String commentCount;
  bool isLiked;

  print('ini datanya : ${dataMore}');

  List<Widget> dataMoreBoxes = [];
  for (var i = 0; i < dataMore.length; i++) {
    teks = dataMore[i]['threadName'].toString();
    date = dataMore[i]['threadDate'].toString();
    idRuangPuan = dataMore[i]['id'];
    likeCount = dataMore[i]['like'].toString();
    // Get comment count from API, default to '0' if not available
    commentCount = (dataMore[i]['comments_count'] ?? 0).toString();
    // Check if current user has liked this post
    isLiked = dataMore[i]['user_liked'] == true ||
        dataMore[i]['is_liked'] == true ||
        dataMore[i]['liked'] == true;
    print(
        '${teks} - ${date} - ${likeCount} - comments: ${commentCount} - liked: ${isLiked}');
    dataMoreBoxes.add(MoreBox(
      date: date,
      teks: teks,
      idRuangPuan: idRuangPuan,
      likeCount: likeCount,
      commentCount: commentCount,
      initialIsLiked: isLiked,
    ));
    dataMoreBoxes.add(SizedBox(height: 10));
  }
  return Column(
    children: dataMoreBoxes,
  );
}

class MoreBox extends StatefulWidget {
  const MoreBox({
    super.key,
    required this.date,
    required this.teks,
    required this.idRuangPuan,
    required this.likeCount,
    required this.commentCount,
    this.initialIsLiked = false,
  });

  final String date;
  final String teks;
  final String likeCount;
  final String commentCount;
  final int idRuangPuan;
  final bool initialIsLiked;

  @override
  State<MoreBox> createState() => _MoreBoxState();
}

class _MoreBoxState extends State<MoreBox> {
  late bool isLiked;
  late int currentLikeCount;
  bool isLiking = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initialIsLiked;
    currentLikeCount = int.tryParse(widget.likeCount) ?? 0;
    print(
        '🟢 Initialized post ${widget.idRuangPuan} - isLiked: $isLiked, count: $currentLikeCount');
  }

  Future<void> toggleLike() async {
    if (isLiking) return;

    setState(() {
      isLiking = true;
    });

    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/ruang-puan/${widget.idRuangPuan}/like');

      print('🔵 Attempting to like post: ${widget.idRuangPuan}');
      print('🔵 URL: $url');
      print('🔵 Headers: ${AuthService.getAuthHeaders()}');

      final response = await http.post(
        url,
        headers: AuthService.getAuthHeaders(),
      );

      print('🔵 Response Status: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔵 JSON Response: $jsonResponse');

        final data = jsonResponse['data'] as Map<String, dynamic>;
        print('🔵 Data: $data');
        print('🔵 Liked: ${data['liked']}');
        print('🔵 Likes Total: ${data['likes_total']}');

        setState(() {
          isLiked = data['liked'] as bool? ?? !isLiked;
          currentLikeCount =
              int.tryParse(data['likes_total']?.toString() ?? '0') ??
                  currentLikeCount;
          isLiking = false;
        });

        print(
            '✅ Like updated successfully - isLiked: $isLiked, count: $currentLikeCount');
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');

        setState(() {
          isLiking = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to update like status (${response.statusCode})'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Exception occurred: $e');
      print('❌ Stack trace: $stackTrace');

      setState(() {
        isLiking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.forum_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Post',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      const SizedBox(width: 6),
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.teks,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(
            height: 1,
            color: AppColors.accent.withOpacity(0.2),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => Comment(
                            idRuangPuan: widget.idRuangPuan,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mode_comment_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Comment',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.commentCount,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.accent.withOpacity(0.2),
                ),
                Expanded(
                  child: InkWell(
                    onTap: isLiking ? null : toggleLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLiking)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          else
                            Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: AppColors.error,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            'Like',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              currentLikeCount.toString(),
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

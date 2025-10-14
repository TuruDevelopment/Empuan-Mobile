import 'package:flutter/material.dart';
import 'package:Empuan/screens/commentRuangPuan.dart';
import 'package:Empuan/styles/style.dart';

Widget getDataMore(List<dynamic> dataMore) {
  String date;
  String teks;
  int idRuangPuan;
  String likeCount;
  String commentCount;

  print('ini datanya : ${dataMore}');

  List<Widget> dataMoreBoxes = [];
  for (var i = 0; i < dataMore.length; i++) {
    teks = dataMore[i]['threadName'].toString();
    date = dataMore[i]['threadDate'].toString();
    idRuangPuan = dataMore[i]['id'];
    likeCount = dataMore[i]['like'].toString();
    // Get comment count from API, default to '0' if not available
    commentCount = (dataMore[i]['commentRuangPuans'] != null
            ? dataMore[i]['commentRuangPuans'].length
            : 0)
        .toString();
    print('${teks} - ${date} - ${likeCount} - comments: ${commentCount}');
    dataMoreBoxes.add(MoreBox(
      date: date,
      teks: teks,
      idRuangPuan: idRuangPuan,
      likeCount: likeCount,
      commentCount: commentCount,
    ));
    dataMoreBoxes.add(SizedBox(height: 10));
  }
  return Column(
    children: dataMoreBoxes,
  );
}

class MoreBox extends StatelessWidget {
  const MoreBox({
    super.key,
    required this.date,
    required this.teks,
    required this.idRuangPuan,
    required this.likeCount,
    required this.commentCount,
  });

  final String date;
  final String teks;
  final String likeCount;
  final String commentCount;
  final int idRuangPuan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                        fontFamily: 'Satoshi',
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
                        date,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
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
              teks,
              style: TextStyle(
                fontFamily: 'Satoshi',
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
                            idRuangPuan: idRuangPuan,
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
                              fontFamily: 'Satoshi',
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
                              commentCount,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Like',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
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
                            likeCount,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

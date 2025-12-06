import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/screens/isiSuaraPuan.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

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
          final kategoriName = snapshot.data ?? 'Loading...';

          return SuaraPuanBox(
            id: id,
            title: title,
            content: content,
            media: media,
            dop: dop,
            kategori_id: kategori_id,
            user_id: user_id,
            kategori_name: kategoriName,
            video: video,
          );
        },
      );
    }).toList(),
  );
}

class SuaraPuanBox extends StatelessWidget {
  SuaraPuanBox(
      {super.key,
      required this.id,
      required this.title,
      required this.content,
      required this.media,
      required this.dop,
      required this.kategori_id,
      required this.user_id,
      required this.kategori_name,
      required this.video});

  final String id;
  final String title;
  final String content;
  final String media;
  final String dop;
  final String kategori_id;
  final String user_id;
  final String kategori_name;
  final String video;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          // Image Section
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => IsiSuaraPuan(
                        id: id,
                        title: title,
                        content: content,
                        media: media,
                        dop: dop,
                        kategori_id: kategori_id,
                        user_id: user_id,
                        video: video,
                      )));
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: 180,
                child: Image.network(
                  media,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.accent.withOpacity(0.1),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: AppColors.textSecondary,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Date
                Row(
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryVariant,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.label_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            kategori_name,
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Date
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dop,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Read More Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => IsiSuaraPuan(
                                id: id,
                                title: title,
                                content: content,
                                media: media,
                                dop: dop,
                                kategori_id: kategori_id,
                                user_id: user_id,
                                video: video,
                              )));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Read More',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
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

Future<String?> getKategoriById(String kategoriId) async {
  final url = '${ApiConfig.baseUrl}/kategori-suara-puan/$kategoriId';
  final uri = Uri.parse(url);
  final response = await http.get(uri, headers: AuthService.getAuthHeaders());

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map;
    final result = json['data'];
    if (result != null && result.containsKey('nama')) {
      return result['nama'].toString();
    }
  }

  return 'Category';
}

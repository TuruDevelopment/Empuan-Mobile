import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/components/skeleton_loading.dart';
import 'package:Empuan/screens/isiSuaraPuan.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

class SuaraPuan extends StatefulWidget {
  // const SuaraPuan({super.key});
  const SuaraPuan({Key? key}) : super(key: key);

  @override
  // State<SuaraPuan> createState() => _SuaraPuanState();
  _SuaraPuanState createState() => _SuaraPuanState();
}

class _SuaraPuanState extends State<SuaraPuan> {
  bool isLoading = true;

  void initState() {
    super.initState();
    getData();
  }

  List<dynamic> dataSuaraPuan = [];
  List<dynamic> dataBannerSuara = [];

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Modern Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Back Button
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
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Section Title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'For You',
                              style: TextStyle(
                                fontFamily: 'Brodies',
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Article List - all items as vertical cards
                      Container(
                        child: Column(
                          children: [
                            isLoading
                                ? buildSuaraPuanSkeletonList(itemCount: 4)
                                : getDataSuaraPuan(dataSuaraPuan),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
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
    final url = '${ApiConfig.baseUrl}/suara-puan';
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map;
      final List<dynamic> resultList = jsonResponse['data'] ?? [];

      for (var data in resultList) {
        var id = data['id'].toString();
        var title = data['title'].toString();
        var content = data['content'].toString();
        var media = data['media'].toString();
        var dop = data['dop'].toString();
        var kategori_id = data['kategori_id'].toString();
        var video = data['video'].toString();

        dataSuaraPuan.add({
          'id': id,
          'title': title,
          'content': content,
          'media': media,
          'video': video,
          'dop': dop,
          'kategori_id': kategori_id,
        });
      }

      setState(() {
        // Update state after fetching data
        dataSuaraPuan = resultList;
        dataBannerSuara = dataSuaraPuan.take(4).toList();

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false; // Set isLoading to false if request failed
      });
    }
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }
}

class BannerWidget extends StatelessWidget {
  final dynamic data;

  const BannerWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Flexible(
            flex: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => IsiSuaraPuan(
                          id: data['id'].toString(),
                          title: data['title'].toString(),
                          content: data['content'].toString(),
                          media: data['media'].toString(),
                          dop: data['dop'].toString(),
                          kategori_id: data['kategori_id'].toString(),
                          user_id: data['user_id'].toString(),
                          video: data['video'].toString(),
                        )));
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  child: Image.network(
                    data['media'].toString(),
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
          ),
          // Info Section
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Icon(
                          Icons.label_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          getCategory(
                              int.parse(data['kategori_id'].toString())),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Flexible(
                    child: Text(
                      data['title'].toString(),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                        data['dop'].toString(),
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

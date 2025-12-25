import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Empuan/components/dataUntukPuan.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;
import 'package:Empuan/config/api_config.dart';

class newUntukPuan extends StatefulWidget {
  const newUntukPuan({super.key});

  @override
  State<newUntukPuan> createState() => _newUntukPuanState();
}

class _newUntukPuanState extends State<newUntukPuan> {
  final ScrollController _scrollController = ScrollController();
  final PageController controller = PageController();
  final TextEditingController searchController = TextEditingController();

  int currentTab = 0;
  String searchQuery = '';
  bool isLoading = true;

  List<dynamic> dataUntukPuan = [];
  List<dynamic> kategoriList = [];

  @override
  void initState() {
    super.initState();
    fetchKategori();
    fetchUntukPuan();
  }

  /// ================= FILTER KATEGORI + SEARCH =================
  List<dynamic> get filteredData {
    if (kategoriList.isEmpty) return [];

    final selectedKategoriId = kategoriList[currentTab]['id'];

    return dataUntukPuan.where((item) {
      final matchKategori =
          item['kategori_id'].toString() == selectedKategoriId.toString();

      final matchSearch = searchQuery.isEmpty
          ? true
          : item['nama'].toString().toLowerCase().contains(searchQuery) ||
              item['alamat'].toString().toLowerCase().contains(searchQuery);

      return matchKategori && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final content = filteredData.isEmpty
        ? const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: Text(
                'Kategori ini belum memiliki data',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: getDataUntukPuan(filteredData),
          );

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
              /// ================= HEADER (SEARCH FIXED) =================
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search recommendations...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: _scrollController,
                  children: [
                    /// ================= BANNER (TIDAK DIUBAH) =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.secondary,
                              AppColors.secondary.withOpacity(0.8),
                              AppColors.accent.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -30,
                              top: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -20,
                              bottom: -20,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.spa_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'For Her',
                                    style: TextStyle(
                                      fontFamily: 'Brodies',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Find the best places for your wellness',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ================= KATEGORI =================
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(kategoriList.length, (index) {
                            final isActive = currentTab == index;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  currentTab = index;
                                  searchQuery = '';
                                  searchController.clear();
                                });
                                controller.jumpToPage(index);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isActive
                                      ? LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primaryVariant,
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.accent.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  kategoriList[index]['nama_kategori'],
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ================= CONTENT =================
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.62,
                      child: PageView.builder(
                        controller: controller,
                        itemCount: kategoriList.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentTab = index;
                            searchQuery = '';
                            searchController.clear();
                          });
                        },
                        itemBuilder: (_, __) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 180),
                            child: content,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= FETCH KATEGORI =================
  Future<void> fetchKategori() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/kategori-untuk-puan'),
      headers: {'Authorization': 'Bearer ${AuthService.token}'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        kategoriList = json['data'] ?? [];
      });
    }
  }

  /// ================= FETCH UNTUK PUAN =================
  Future<void> fetchUntukPuan() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/untuk-puan'),
      headers: {'Authorization': 'Bearer ${AuthService.token}'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        dataUntukPuan = json['data'] ?? [];
        isLoading = false;
      });
    }
  }
}

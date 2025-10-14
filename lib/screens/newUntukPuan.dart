import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:Empuan/components/dataUntukPuan.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

class newUntukPuan extends StatefulWidget {
  const newUntukPuan({super.key});

  @override
  State<newUntukPuan> createState() {
    return _newUntukPuanState();
  }
}

class _newUntukPuanState extends State<newUntukPuan> {
  final ScrollController _scrollController = ScrollController();

  bool isLoading = true;

  void initState() {
    super.initState();
    getData();
  }

  List<dynamic> dataUntukPuan = [];

  // final DataUntukPuan = [
  //   ['Spa', 'image', 'Sentul'],
  //   ['Spa', 'image', 'Sentul'],
  //   ['Spa', 'image', 'Sentul'],
  // ];

  final dataUser = ['Nixonnn', 'images/profilePict.png', '12345'];

  final PageController controller = PageController();
  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    Widget konten = getDataUntukPuan(dataUntukPuan);
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
                    const SizedBox(width: 12),
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 48,
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
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search recommendations...',
                            hintStyle: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Settings Button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  children: [
                    // Banner Card
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
                            // Decorative circles
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
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.spa_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Untuk Puan',
                                    style: TextStyle(
                                      fontFamily: 'Brodies',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Find the best places for your wellness',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
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
                    // Sticky Header with Tabs
                    StickyHeader(
                      controller: _scrollController,
                      header: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20.0),
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
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: NavBar(
                            currentTab: currentTab,
                            onTabChanged: (index) {
                              controller.jumpToPage(index);
                            },
                          ),
                        ),
                      ),
                      content: Container(
                        height: (260 * dataUntukPuan.length) + 120,
                        child: PageView(
                          controller: controller,
                          onPageChanged: (index) {
                            setState(() {
                              currentTab = index;
                            });
                          },
                          children: [konten, konten, konten],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
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
    final url = 'http://192.168.8.83:8000/api/untukpuans';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map;
      final List<dynamic> resultList = jsonResponse['data'] ?? [];

      for (var data in resultList) {
        var nama = data['nama'].toString();
        var alamat = data['alamat'].toString();
        var deskripsi = data['deskripsi'].toString();
        var phoneNumber = data['phoneNumber'].toString();
        var jamBuka = data['jamBuka'].toString();
        var jamTutup = data['jamTutup'].toString();
        var foto = data['foto'].toString();
        var price = data['price'].toString();
        var website = data['website'].toString();
        var kategori_id = data['kategori_id'].toString();

        dataUntukPuan.add({
          'nama': nama,
          'alamat': alamat,
          'deskripsi': deskripsi,
          'phoneNumber': phoneNumber,
          'jamBuka': jamBuka,
          'jamTutup': jamTutup,
          'foto': foto,
          'price': price,
          'website': website,
          'kategori_id': kategori_id
        });
      }

      setState(() {
        // Update state after fetching data
        dataUntukPuan = resultList;
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

class NavBar extends StatelessWidget {
  const NavBar({Key? key, required this.onTabChanged, required this.currentTab})
      : super(key: key);

  final void Function(int) onTabChanged;
  final int currentTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTab('Spa & Massage', 0),
        _buildTab('Saloon', 1),
        _buildTab('Food', 2),
      ],
    );
  }

  Widget _buildTab(String text, int index) {
    final isActive = currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryVariant,
                    ],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Satoshi',
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

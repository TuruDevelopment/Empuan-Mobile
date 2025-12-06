import 'package:flutter/material.dart';
import 'package:Empuan/components/bannerUntukPuan.dart';
import 'package:Empuan/styles/style.dart';

class WidgetUntukPuan extends StatefulWidget {
  final String nama;
  final String alamat;
  final String deskripsi;
  final String phoneNumber;
  final String jamBuka;
  final String jamTutup;
  final String foto;
  final String price;
  final String website;
  final String kategori_id;

  const WidgetUntukPuan({
    Key? key,
    required this.nama,
    required this.alamat,
    required this.deskripsi,
    required this.phoneNumber,
    required this.jamBuka,
    required this.jamTutup,
    required this.foto,
    required this.price,
    required this.website,
    required this.kategori_id,
  }) : super(key: key);

  @override
  State<WidgetUntukPuan> createState() => _SuaraPuanState();
}

class _SuaraPuanState extends State<WidgetUntukPuan> {
  @override
  Widget build(BuildContext context) {
    final dataUntukPuan = [
      ['images/spa.png'],
      ['images/spa.png'],
      ['images/spa.png'],
      ['images/spa.png'],
    ];

    final dataBannerUntuk = dataUntukPuan;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: TextField(
            style: const TextStyle(
              fontFamily: 'Satoshi',
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(
                fontFamily: 'Satoshi',
                color: AppColors.textSecondary,
              ),
              suffixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              onPressed: () {
                // do something
              },
            ),
          )
        ],
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Hero Image Banner
            Container(
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.foto,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withOpacity(0.6),
                                AppColors.primaryVariant.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_rounded,
                              color: Colors.white,
                              size: 80,
                            ),
                          ),
                        );
                      },
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
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
                  // Name
                  Text(
                    widget.nama,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Address
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.alamat,
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Open Hours
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Open Hours: ${widget.jamBuka} - ${widget.jamTutup}",
                        style: const TextStyle(
                          fontFamily: 'Satoshi',
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Rating & Price Row
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.star_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "5.0",
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.teal.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.monetization_on_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "\$\$\$\$",
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Distance
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // About Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryVariant,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "About",
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.deskripsi,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Product/Service Catalog Section

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

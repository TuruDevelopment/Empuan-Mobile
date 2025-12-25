import 'package:flutter/material.dart';
import 'package:Empuan/components/widgetUntukPuan.dart';
import 'package:Empuan/styles/style.dart';

Widget _buildFilterChip(String label, IconData icon) {
  return Expanded(
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 13,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget getDataUntukPuan(List<dynamic> dataUntukPuan) {
  List<Widget> dataUntukPuanBoxes = [];
  dataUntukPuanBoxes.add(const SizedBox(height: 16));

  // Section Title
  dataUntukPuanBoxes.add(
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            Icons.recommend_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            'Our Recommendations',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    ),
  );

  dataUntukPuanBoxes.add(const SizedBox(height: 16));

  for (var i = 0; i < dataUntukPuan.length; i++) {
    final item = dataUntukPuan[i];

    dataUntukPuanBoxes.add(
      UntukPuanBox(
        nama: item['nama'].toString(),
        alamat: item['alamat'].toString(),
        deskripsi: item['deskripsi'].toString(),
        phoneNumber: item['phoneNumber'].toString(),
        jamBuka: item['jamBuka'].toString(),
        jamTutup: item['jamTutup'].toString(),
        foto: item['foto'].toString(),
        price: item['price'].toString(),
        website: item['website'].toString(),
        kategori_id: item['kategori_id'].toString(),
      ),
    );

    dataUntukPuanBoxes.add(const SizedBox(height: 16));
  }

  return Column(children: dataUntukPuanBoxes);
}

class UntukPuanBox extends StatelessWidget {
  const UntukPuanBox({
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WidgetUntukPuan(
              nama: nama,
              alamat: alamat,
              deskripsi: deskripsi,
              phoneNumber: phoneNumber,
              jamBuka: jamBuka,
              jamTutup: jamTutup,
              foto: foto,
              price: price,
              website: website,
              kategori_id: kategori_id,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= IMAGE (FIX DI SINI SAJA) =================
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(foto), // ✅ FIX
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // ================= INFO =================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alamat,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
}

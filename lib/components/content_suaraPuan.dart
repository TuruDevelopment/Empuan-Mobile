import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tumpuan/components/callView.dart';
import 'package:tumpuan/components/editContact.dart';
import 'package:tumpuan/screens/isiSuaraPuan.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;

// Widget getDataSuaraPuan(List<dynamic> dataSuaraPuan) {
//   String id;
//   String title;
//   String content;
//   String media;
//   String dop;
//   String kategori_id;
//   String user_id;

//   List<Widget> dataSuaraBoxes = [];
//   for (var i = 0; i < dataSuaraPuan.length; i++) {
//     id = dataSuaraPuan[i]['id'].toString();
//     title = dataSuaraPuan[i]['title'].toString();
//     content = dataSuaraPuan[i]['content'].toString();
//     media = dataSuaraPuan[i]['media'].toString();
//     dop = dataSuaraPuan[i]['dop'].toString();
//     kategori_id = dataSuaraPuan[i]['kategori_id'].toString();
//     user_id = dataSuaraPuan[i]['user_id'].toString();

//     // dataSuaraBoxes.add(FutureBuilder<String?>(
//     //   future: getKategoriById(kategori_id),
//     //   builder: (context, snapshot) {
//     //     // if (snapshot.connectionState == ConnectionState.waiting) {
//     //     //   return CircularProgressIndicator(); // Tampilkan loading indicator jika masih dalam proses pengambilan data
//     //     // } else if (snapshot.hasError) {
//     //     //   return Text('Error: ${snapshot.error}');
//     //     // } else {
//     //     String kategoriName =
//     //         snapshot.data ?? ''; // Gunakan string kosong jika nilai null
//     //     return SuaraPuanBox(
//     //       id: id,
//     //       title: title,
//     //       content: content,
//     //       media: media,
//     //       dop: dop,
//     //       kategori_id: kategori_id,
//     //       user_id: user_id,
//     //       kategori_name: kategoriName,
//     //     );
//     //     // }
//     //   },
//     // ));

//     dataSuaraBoxes.add(FutureBuilder<String?>(
//       future: getKategoriById(kategori_id),
//       builder: (context, snapshot) {
//         String kategoriName =
//             snapshot.data ?? ''; // Gunakan string kosong jika nilai null
//         return SuaraPuanBox(
//           id: id,
//           title: title,
//           content: content,
//           media: media,
//           dop: dop,
//           kategori_id: kategori_id,
//           user_id: user_id,
//           kategori_name: kategoriName,
//         );
//       },
//     ));

//     // String? kategoriName = await getKategoriById(kategori_id);

//     // dataSuaraBoxes.add(SuaraPuanBox(
//     //     id: id,
//     //     title: title,
//     //     content: content,
//     //     media: media,
//     //     dop: dop,
//     //     kategori_id: kategori_id,
//     //     user_id: user_id,
//     //     kategori_name: kategoriName ?? ''));
//     dataSuaraBoxes.add(SizedBox(height: 10));
//   }
//   return Column(
//     children: dataSuaraBoxes,
//   );
// }

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
      // final kategori_name = data['kategori_id

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
    return Column(
      children: [
        Container(
          width: 330,
          child: Divider(
            color: Colors.grey,
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          decoration: BoxDecoration(
              // color: Colors.white,
              // border: Border.symmetric()
              // borderRadius: BorderRadius.all(Radius.circular(10))
              ),
          // height: 200,
          width: 330,
          child: Center(
            // padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        kategori_name,
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 20),
                      ),
                      SizedBox(
                        height: 20,
                        width: 100,
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
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                const Color.fromRGBO(251, 111, 146, 1)),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            )),
                          ),
                          child: const Text(
                            'See More',
                            style: TextStyle(fontFamily: 'Satoshi'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // Action to perform when the Container is tapped
                    print('Container tapped');
                  },
                  child: Container(
                    width: 325,
                    height: 148,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: GestureDetector(
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
                      child: Image.network(
                        media,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Text(dop,
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.bold,
                              color: const Color.fromRGBO(251, 111, 146, 1),
                              fontSize: 12)),
                      VerticalDivider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                      Text(kategori_name,
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.bold,
                              color: const Color.fromRGBO(251, 111, 146, 1),
                              fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  title,
                  style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 20),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<String?> getKategoriById(String kategoriId) async {
  final url = 'http://10.0.2.2:8000/api/kategorisuarapuans/$kategoriId';
  final uri = Uri.parse(url);
  final response =
      await http.get(uri, headers: {'Authorization': '${AuthService.token}'});

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map;
    final result = json['data'];
    if (result != null && result.containsKey('nama')) {
      return result['nama'].toString();
    }
  }

  return null;
}

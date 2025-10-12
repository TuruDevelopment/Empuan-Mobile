import 'package:flutter/material.dart';

Widget getDataBannerSuaraPuan(List<String> dataBannerSuara) {
  String title;
  String media;
  String dop;
  String kategori_id;
  String user_id;

  List<Widget> dataBannerSuaraBoxes = [];
  // for (var i = 0; i < dataBannerSuara.length; i++) {

  //   dataBannerSuaraBoxes.add(SizedBox(height: 10));
  // }
  // author = dataBannerSuara[0];
  // image = dataBannerSuara[1];
  // date = dataBannerSuara[2];
  // category = dataBannerSuara[3];
  // title = dataBannerSuara[4];

  title = dataBannerSuara[0];
  media = dataBannerSuara[1];
  dop = dataBannerSuara[2];
  kategori_id = dataBannerSuara[3];
  user_id = dataBannerSuara[4];

  dataBannerSuaraBoxes.add(BannerSuaraPuanBox(
    title: title,
    media: media,
    dop: dop,
    kategori_id: kategori_id,
    user_id: user_id,
  ));
  return Column(
    children: dataBannerSuaraBoxes,
  );
}

class BannerSuaraPuanBox extends StatelessWidget {
  BannerSuaraPuanBox(
      {super.key,
      required this.title,
      required this.media,
      required this.dop,
      required this.kategori_id,
      required this.user_id});

  final String title;
  final String media;
  final String dop;
  final String kategori_id;
  final String user_id;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
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
                Container(
                  width: 390,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: AssetImage(media),
                      fit: BoxFit.cover,
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
                      Text(kategori_id,
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.bold,
                              color: const Color.fromRGBO(251, 111, 146, 1),
                              fontSize: 12)),
                    ],
                  ),
                ),
                // SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Text(
                    title,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 20),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

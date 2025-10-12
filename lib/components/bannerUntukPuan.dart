import 'package:flutter/material.dart';
import 'package:tumpuan/components/callView.dart';
import 'package:tumpuan/components/editContact.dart';
import 'package:tumpuan/styles/style.dart';

Widget getDataBannerUntukPuan(List<String> dataBannerUntuk) {
  String image;
  List<Widget> dataBannerUntukBoxes = [];
  // for (var i = 0; i < dataBannerSuara.length; i++) {

  //   dataBannerUntukBoxes.add(SizedBox(height: 10));
  // }
  image = dataBannerUntuk[0];

  dataBannerUntukBoxes.add(BannerUntukPuanBox(
    image: image,
  ));
  return Column(
    children: dataBannerUntukBoxes,
  );
}

class BannerUntukPuanBox extends StatelessWidget {
  BannerUntukPuanBox({
    super.key,
    required this.image,
  });

  final String image;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              // color: Colors.white,
              // border: Border.symmetric()
              // borderRadius: BorderRadius.all(Radius.circular(10))
              ),
          // height: 200,
          width: 600,
          child: Center(
            // padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              children: [
                Container(
                  width: 500,
                  height: 180,
                  decoration: BoxDecoration(
                      image: DecorationImage(image: AssetImage(image))),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

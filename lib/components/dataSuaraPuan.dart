import 'package:flutter/material.dart';

Widget getDataDataSuaraPuan(List<List<String>> dataDataSuaraPuan) {
  String header;
  String title;
  String datetime;
  String category;
  String text;
  List<Widget> dataDataSuaraBoxes = [];

  for (var i = 0; i < dataDataSuaraPuan.length; i++) {
    header = dataDataSuaraPuan[i][0];
    title = dataDataSuaraPuan[i][1];
    datetime = dataDataSuaraPuan[i][2];
    category = dataDataSuaraPuan[i][3];
    text = dataDataSuaraPuan[i][4];
    dataDataSuaraBoxes.add(DataSuaraPuanBox(
      header: header,
      title: title,
      datetime: datetime,
      category: category,
      text: text,
    ));
    dataDataSuaraBoxes.add(SizedBox(height: 10));
  }

  return Column(
    children: dataDataSuaraBoxes,
  );
}

class DataSuaraPuanBox extends StatelessWidget {
  DataSuaraPuanBox(
      {super.key,
      required this.header,
      required this.title,
      required this.datetime,
      required this.category,
      required this.text});

  final String header;
  final String title;
  final String datetime;
  final String category;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 20,
        ),
        Container(
          width: 330,
          height: 200,
          child: Center(
              child: Column(
            children: [
              Container(
                height: 170,
                // decoration: BoxDecoration(
                //     image: DecorationImage(image: AssetImage(header))),
              )
            ],
          )),
        )
      ],
    );
  }
}

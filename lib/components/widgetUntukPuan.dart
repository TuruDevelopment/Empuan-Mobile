import 'package:flutter/material.dart';
import 'package:tumpuan/Widgets/sliver_list.dart';
import 'package:tumpuan/Widgets/sliver_list2.dart';
import 'package:tumpuan/Widgets/sliver_list3.dart';
import 'package:tumpuan/components/bannerSuaraPuan.dart';
import 'package:tumpuan/components/bannerUntukPuan.dart';
import 'package:tumpuan/components/content_suaraPuan.dart';

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

    final PageController controller = PageController();
    int currentTab = 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: TextField(
          decoration: InputDecoration(
              suffixIcon: Icon(Icons.search, color: Colors.black)),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.black,
            ),
            onPressed: () {
              // do something
            },
          )
        ],
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 30),
            Container(
              height: 230,
              child: PageView(
                controller: controller,
                onPageChanged: (int index) {
                  setState(() {
                    currentTab = index;
                  });
                },
                children: [
                  for (var item in dataBannerUntuk) getDataBannerUntukPuan(item)
                ],
              ),
            ),
            Container(
              // alignment: Alignment.topLeft,
              height: 100,
              child: Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          widget.nama,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          widget.alamat,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 17),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Open Hours: " +
                              widget.jamBuka +
                              " - " +
                              widget.jamTutup,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontFamily: 'Satoshi',
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                              fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 20,
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 20,
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 20,
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 20,
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.monetization_on,
                            color: Colors.green, size: 20),
                        Icon(Icons.monetization_on,
                            color: Colors.green, size: 20),
                        Icon(Icons.monetization_on,
                            color: Colors.green, size: 20),
                        Icon(Icons.monetization_on,
                            color: Colors.green, size: 20),
                        SizedBox(width: 10),
                        Icon(Icons.location_pin, color: Colors.grey, size: 20),
                        Text("0.1 km from you",
                            style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                                fontSize: 14)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: 340,
              child: Divider(
                color: Colors.grey,
                thickness: 1.5,
                height: 10,
              ),
            ),
            Container(
              // height: 360,
              child: Padding(
                padding: const EdgeInsets.only(left: 40, top: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("About",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 340,
                          child: Text(
                            widget.deskripsi,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 17),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            Container(
              width: 340,
              child: Divider(
                color: Colors.grey,
                thickness: 1.5,
                height: 10,
              ),
            ),
            Container(
              height: 400,
              child: Padding(
                padding: const EdgeInsets.only(left: 40, top: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Product/Service Catalog",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                        SizedBox(height: 10),
                      ],
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Container(
                        height: 230,
                        child: PageView(
                          controller: controller,
                          onPageChanged: (int index) {
                            setState(() {
                              currentTab = index;
                            });
                          },
                          children: [
                            for (var item in dataBannerUntuk)
                              getDataBannerUntukPuan(item)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

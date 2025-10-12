import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:tumpuan/components/callView.dart';
import 'package:tumpuan/components/editContact.dart';
import 'package:tumpuan/components/widgetUntukPuan.dart';
import 'package:tumpuan/screens/commentRuangPuan.dart';
import 'package:tumpuan/screens/more.dart';
import 'package:tumpuan/styles/style.dart';

Widget getDataUntukPuan(List<dynamic> dataUntukPuan) {
  String nama;
  String alamat;
  String deskripsi;
  String phoneNumber;
  String jamBuka;
  String jamTutup;
  String foto;
  String price;
  String website;
  String kategori_id;

  print('ini datanya : ${dataUntukPuan}');

  List<Widget> dataUntukPuanBoxes = [];
  dataUntukPuanBoxes.add(SizedBox(height: 5));
  dataUntukPuanBoxes.add(Container(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 70,
              height: 20,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(
                  'Near Me',
                  style: TextStyle(fontFamily: 'Satoshi', fontSize: 10),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 70,
              height: 20,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(
                  'Rated 4 Star',
                  style: TextStyle(fontFamily: 'Satoshi', fontSize: 10),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 70,
              height: 20,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(
                  'Cheapest Price',
                  style: TextStyle(fontFamily: 'Satoshi', fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      )));
  dataUntukPuanBoxes.add(SizedBox(height: 15));
  dataUntukPuanBoxes.add(Text(
    'Our Recommendations For You',
    style: TextStyle(
        fontFamily: 'Satoshi', fontWeight: FontWeight.bold, fontSize: 20),
  ));
  dataUntukPuanBoxes.add(SizedBox(height: 15));
  for (var i = 0; i < dataUntukPuan.length; i++) {
    // name = DataUntukPuan[i]['threadName'].toString();
    // address = DataUntukPuan[i]['threadDate'].toString();
    // image = "lala";
    nama = dataUntukPuan[i]['nama'].toString();
    alamat = dataUntukPuan[i]['alamat'].toString();
    deskripsi = dataUntukPuan[i]['deskripsi'].toString();
    phoneNumber = dataUntukPuan[i]['phoneNumber'].toString();
    jamBuka = dataUntukPuan[i]['jamBuka'].toString();
    jamTutup = dataUntukPuan[i]['jamTutup'].toString();
    foto = dataUntukPuan[i]['foto'].toString();
    price = dataUntukPuan[i]['price'].toString();
    website = dataUntukPuan[i]['website'].toString();
    kategori_id = dataUntukPuan[i]['kategori_id'].toString();

    dataUntukPuanBoxes.add(UntukPuanBox(
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
    ));
    dataUntukPuanBoxes.add(SizedBox(height: 15));
  }
  return Column(
    children: dataUntukPuanBoxes,
  );
}

class UntukPuanBox extends StatelessWidget {
  UntukPuanBox({
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

  int checker = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
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
                )));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Stack(children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                          image: AssetImage(foto), fit: BoxFit.fill)),
                ),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: 5,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Container(
                                width: MediaQuery.of(context).size.width - 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      nama,
                                      style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ],
                                )),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: Container(
                                width: MediaQuery.of(context).size.width - 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      alamat,
                                      style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontWeight: FontWeight.w100,
                                          fontSize: 12),
                                    ),
                                  ],
                                )),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 190, top: 190),
            child: Container(
                height: 20,
                width: MediaQuery.of(context).size.width / 2 - 55,
                decoration: BoxDecoration(
                    color: AppColors.pink1,
                    borderRadius: BorderRadius.circular(5)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 13,
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 13,
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 13,
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 13,
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 13,
                    ),
                    VerticalDivider(
                      color: Colors.white,
                      thickness: 0.5,
                    ),
                    Icon(Icons.monetization_on, color: Colors.green, size: 13),
                    Icon(Icons.monetization_on, color: Colors.green, size: 13),
                    Icon(Icons.monetization_on, color: Colors.green, size: 13),
                    Icon(Icons.monetization_on, color: Colors.green, size: 13),
                  ],
                )),
          )
        ]),
      ),
    );
  }
}

// import 'dart:html';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tumpuan/components/callView.dart';
import 'package:tumpuan/components/editContact.dart';
import 'package:tumpuan/screens/commentRuangPuan.dart';
import 'package:tumpuan/screens/more.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;

Widget getDataMore(List<dynamic> dataMore) {
  // More objectMore = new More();

  // objectMore.

  String username;
  String profilePict;
  // String image;
  String date;
  String teks;
  // String media;
  int idRuangPuan;
  String likeCount;
  String commentCount;

  // print('ini datanya : ${dataMore[0][0]}');
  print('ini datanya : ${dataMore}');

  List<Widget> dataMoreBoxes = [];
  for (var i = 0; i < dataMore.length; i++) {
    // username = dataMore[i][0];
    // profilePict = dataMore[i][1];
    teks = dataMore[i]['threadName'].toString();
    date = dataMore[i]['threadDate'].toString();
    // image = "lala";
    // media = dataMore[i]['media'].toString();
    // teks = dataMore[i][1] != null ? dataMore[i][1].toString() : '';
    // date = dataMore[i][2] != null ? dataMore[i][1].toString() : '';
    // image = dataMore[i][3] != null ? dataMore[i][1].toString() : '';
    idRuangPuan = dataMore[i]['id'];
    // likeCount = dataMore[i][4] != null ? dataMore[i][1].toString() : '';
    likeCount = dataMore[i]['like'].toString();
    // commentCount = dataMore[i][7];
    print('${teks} - ${date} - ${likeCount} ');
    dataMoreBoxes.add(MoreBox(
      // username: username,
      // profilePict: profilePict,
      // media: media,
      date: date,
      teks: teks,
      idRuangPuan: idRuangPuan,
      // idPost: idPost,
      likeCount: likeCount,
      // commentCount: commentCount,
    ));
    dataMoreBoxes.add(SizedBox(height: 10));
  }
  return Column(
    children: dataMoreBoxes,
  );
}

class MoreBox extends StatelessWidget {
  // var username;

  MoreBox({
    super.key,
    // required this.username,
    // required this.profilePict,
    // required this.image,
    required this.date,
    required this.teks,
    // required this.media,
    // required this.idPost,
    required this.idRuangPuan,
    required this.likeCount,
    // required this.commentCount
  });

  // late final String username;
  // final String profilePict;
  // final String image;
  final String date;
  final String teks;
  // final String media;
  // final String idPost;
  final String likeCount;
  final int idRuangPuan;
  // final String commentCount;

  int checker = 1;

  // if(length(img) = 0)

  @override
  Widget build(BuildContext context) {
    // late String userName;
    // bool showImage = media.isNotEmpty;
    return Center(
        child: Container(
      // height: 100,
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              // height: 100,
              // decoration: BoxDecoration(color: Colors.amber),
              child: Row(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  // CircleAvatar(
                  //   backgroundImage: AssetImage(profilePict),
                  //   radius: 30,
                  // ),
                  SizedBox(
                    width: 20,
                  ),
                  Container(
                    width: 270,
                    // decoration: BoxDecoration(color: Colors.grey),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Text(
                            //   username,
                            //   style: TextStyle(
                            //       fontFamily: 'Satoshi',
                            //       fontWeight: FontWeight.bold,
                            //       fontSize: 15),
                            // ),
                            Text(
                              date,
                              style: TextStyle(
                                  fontFamily: 'Satoshi', fontSize: 15),
                            )
                          ],
                        ),
                        Container(
                          width: 270,
                          // decoration: BoxDecoration(color: Colors.grey),
                          child: Text(
                            teks,
                            style:
                                TextStyle(fontFamily: 'Satoshi', fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          // if(checker = 0){}
          // if (showImage) Image.asset(image),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.mode_comment_outlined),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true)
                            .push(MaterialPageRoute(
                                builder: (context) => Comment(
                                      idRuangPuan: idRuangPuan,
                                    )));
                      },
                    ),
                    // SizedBox(
                    //   width: 5,
                    // ),
                    Text('1')
                  ],
                ),
              ),
              SizedBox(
                width: 15,
              ),
              Container(
                child: Row(
                  children: [
                    Icon(Icons.favorite_border),
                    SizedBox(
                      width: 5,
                    ),
                    Text(likeCount)
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    ));
  }
}

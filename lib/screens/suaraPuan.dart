import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:tumpuan/components/content_suaraPuan.dart';
import 'package:tumpuan/screens/isiSuaraPuan.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:http/http.dart' as http;

class SuaraPuan extends StatefulWidget {
  // const SuaraPuan({super.key});
  const SuaraPuan({Key? key}) : super(key: key);

  @override
  // State<SuaraPuan> createState() => _SuaraPuanState();
  _SuaraPuanState createState() => _SuaraPuanState();
}

class _SuaraPuanState extends State<SuaraPuan> {
  bool isLoading = true;

  void initState() {
    super.initState();
    getData();
  }

  List<dynamic> dataSuaraPuan = [];
  List<dynamic> dataBannerSuara = [];

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 32),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'For You',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontFamily: 'Satoshi-Bold',
                      color: Color.fromRGBO(251, 111, 146, 1),
                      fontWeight: FontWeight.w900,
                      fontSize: 30),
                ),
              ),
            ),
            Container(
              height: 250,
              child: PageView(
                controller: controller,
                onPageChanged: (index) {
                  setState(() {
                    currentTab = index;
                  });
                },
                children: dataSuaraPuan
                    .map((item) => BannerWidget(data: item))
                    .toList(),
              ),
            ),
            Container(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  getDataSuaraPuan(dataSuaraPuan),
                ],
              ),
            )),
            SizedBox(
              height: 30,
            )
          ],
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
    final url = 'http://10.0.2.2:8000/api/suarapuans';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map;
      final List<dynamic> resultList = jsonResponse['data'] ?? [];

      for (var data in resultList) {
        var id = data['id'].toString();
        var title = data['title'].toString();
        var content = data['content'].toString();
        var media = data['media'].toString();
        var dop = data['dop'].toString();
        var kategori_id = data['kategori_id'].toString();
        var video = data['video'].toString();

        dataSuaraPuan.add({
          'id': id,
          'title': title,
          'content': content,
          'media': media,
          'video': video,
          'dop': dop,
          'kategori_id': kategori_id,
        });
      }

      setState(() {
        // Update state after fetching data
        dataSuaraPuan = resultList;
        dataBannerSuara = dataSuaraPuan.take(4).toList();

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

class BannerWidget extends StatelessWidget {
  final dynamic data;

  const BannerWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(33, 17, 33, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // color: Colors.blue,
      ),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
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
                          id: data['id'].toString(),
                          title: data['title'].toString(),
                          content: data['content'].toString(),
                          media: data['media'].toString(),
                          dop: data['dop'].toString(),
                          kategori_id: data['kategori_id'].toString(),
                          user_id: data['user_id'].toString(),
                          video: data['video'].toString(),
                        )));
              },
              child: Image.network(
                data['media'].toString(),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              children: [
                Text(
                  data['dop'].toString(),
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w900,
                    color: const Color.fromRGBO(251, 111, 146, 1),
                    fontSize: 12,
                  ),
                ),
                Text(
                  " | " +
                      getCategory(int.parse(data['kategori_id'].toString())),
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w900,
                    color: const Color.fromRGBO(251, 111, 146, 1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3),
          Text(
            data['title'].toString(),
            style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 20),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

String getCategory(int id) {
  if (id == 1)
    return 'Lifestyle';
  else if (id == 2)
    return 'Business';
  else if (id == 3)
    return 'News';
  else if (id == 4)
    return 'Health';
  else
    return '-';
}

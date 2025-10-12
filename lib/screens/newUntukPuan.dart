import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:tumpuan/components/cardMore.dart';
import 'package:tumpuan/components/dataUntukPuan.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/styles/style.dart';
import '../Widgets/sliver_list.dart';
import '../Widgets/sliver_list2.dart';
import '../Widgets/sliver_list3.dart';
import 'package:http/http.dart' as http;

class newUntukPuan extends StatefulWidget {
  const newUntukPuan({super.key});

  @override
  State<newUntukPuan> createState() {
    return _newUntukPuanState();
  }
}

class _newUntukPuanState extends State<newUntukPuan> {
  final ScrollController _scrollController = ScrollController();

  bool isLoading = true;

  void initState() {
    super.initState();
    getData();
  }

  List<dynamic> dataUntukPuan = [];

  // final DataUntukPuan = [
  //   ['Spa', 'image', 'Sentul'],
  //   ['Spa', 'image', 'Sentul'],
  //   ['Spa', 'image', 'Sentul'],
  // ];

  final dataUser = ['Nixonnn', 'images/profilePict.png', '12345'];

  final PageController controller = PageController();
  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    Widget konten = getDataUntukPuan(dataUntukPuan);
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
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
            onPressed: () {},
          ),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: _scrollController,
          children: [
            // SearchCard(),
            Container(
                child: Card(child: Image.asset('images/bannerUntukPuan.png'))),
            StickyHeader(
              controller: _scrollController,
              header: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: NavBar(
                          onTabChanged: (index) {
                            controller.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          currentTab: currentTab,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              content: Container(
                height: (260 * dataUntukPuan.length) + 120,
                child: PageView(
                  controller: controller,
                  onPageChanged: (index) {
                    setState(() {
                      currentTab = index;
                    });
                  },
                  children: [konten, konten, konten],
                ),
              ),
            ),
            SizedBox(height: 30),
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
    final url = 'http://10.0.2.2:8000/api/untukpuans';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map;
      final List<dynamic> resultList = jsonResponse['data'] ?? [];

      for (var data in resultList) {
        var nama = data['nama'].toString();
        var alamat = data['alamat'].toString();
        var deskripsi = data['deskripsi'].toString();
        var phoneNumber = data['phoneNumber'].toString();
        var jamBuka = data['jamBuka'].toString();
        var jamTutup = data['jamTutup'].toString();
        var foto = data['foto'].toString();
        var price = data['price'].toString();
        var website = data['website'].toString();
        var kategori_id = data['kategori_id'].toString();

        dataUntukPuan.add({
          'nama': nama,
          'alamat': alamat,
          'deskripsi': deskripsi,
          'phoneNumber': phoneNumber,
          'jamBuka': jamBuka,
          'jamTutup': jamTutup,
          'foto': foto,
          'price': price,
          'website': website,
          'kategori_id': kategori_id
        });
      }

      setState(() {
        // Update state after fetching data
        dataUntukPuan = resultList;
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

class NavBar extends StatelessWidget {
  const NavBar({Key? key, required this.onTabChanged, required this.currentTab})
      : super(key: key);

  final void Function(int) onTabChanged;
  final int currentTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTab('Spa & Massage', 0),
        _buildTab('Saloon', 1),
        _buildTab('Food', 2),
      ],
    );
  }

  Widget _buildTab(String text, int index) {
    return MaterialButton(
      minWidth: 40,
      onPressed: () => onTabChanged(index),
      child: Text(
        text,
        style: TextStyle(
          color: currentTab == index
              ? const Color.fromRGBO(251, 111, 146, 1)
              : Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }
}

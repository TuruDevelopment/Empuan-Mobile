import 'package:flutter/material.dart';
import 'package:tumpuan/components/callView.dart';
import 'package:tumpuan/components/editEmergencyContact.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;

Widget getDataEmergencyContact(List<dynamic> dataMore) {
  String name;
  String image = 'images/profileDefault.jpg';
  String number;
  String relation;
  String id;

  List<Widget> dataMoreBoxes = [];
  for (var i = 0; i < dataMore.length; i++) {
    name = dataMore[i]['name'].toString();
    number = dataMore[i]['phoneNumber'].toString();
    relation = dataMore[i]['relation'].toString();
    id = dataMore[i]['id'].toString();

    print('${name} - ${number} - ${relation} - ${id}');

    dataMoreBoxes.add(ContactBox(
      name: name,
      image: image,
      number: number,
      relation: relation,
      id: id,
    ));
    dataMoreBoxes.add(SizedBox(height: 10));
  }
  return Column(
    children: dataMoreBoxes,
  );
}

class ContactBox extends StatelessWidget {
  ContactBox(
      {super.key,
      required this.name,
      required this.image,
      required this.number,
      required this.relation,
      required this.id});

  late final String name;
  final String number;
  final String relation;
  final String image;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          // border: Border.all(Colo),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      height: 130,
      width: 330,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: Column(
          children: [
            // SizedBox(height: 3),
            Container(
              height: 20,
              width: 320,
              alignment: Alignment.bottomRight,
              // color: Colors.amber,
              child: IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  color: Colors.grey,
                ),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          builder: (context) => EditEmergencyContact(
                              name: name,
                              image: image,
                              number: number,
                              relation: relation)));
                },
                iconSize: 15,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(
                        builder: (context) => CallView(
                              name: name,
                              number: number,
                            )));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    // backgroundImage: AssetImage(image),
                    radius: 40,
                  ),
                  SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        // color: Colors.amber,
                        width: 200,
                        child: Text(name,
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColors.pink1,
                            )),
                      ),
                      SizedBox(height: 5),
                      Container(
                        width: 200,
                        child: Text(
                          number,
                          style:
                              TextStyle(fontSize: 15, color: AppColors.pink1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 20,
              width: 320,
              alignment: Alignment.bottomRight,
              // color: Colors.amber,
              child: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.grey,
                ),
                onPressed: () {
                  deleteEmergencyContact(id);
                },
                iconSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteEmergencyContact(String id) async {
    // final id = dataMore.isNotEmpty ? dataMore[0]['id'] : "";
    final url = "http://10.0.2.2:8000/api/kontakamans/$id";
    final uri = Uri.parse(url);
    final response = await http
        .delete(uri, headers: {'Authorization': '${AuthService.token}'});

    if (response.statusCode == 200) {
      print('delete success');
    } else {
      print('delete failed');
    }
  }
}

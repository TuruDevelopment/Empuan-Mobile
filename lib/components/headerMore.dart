import 'package:flutter/material.dart';
import 'package:tumpuan/screens/editProfile.dart';
import 'package:tumpuan/screens/settings.dart';
import 'package:tumpuan/styles/style.dart';

class HeaderMore extends StatelessWidget {
  HeaderMore({
    super.key,
    required String this.username,
    required String this.img,
  });

  late String username;
  late String img;
  // late String userid;

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 120,
      child: Card(
        child: Padding(
            padding: EdgeInsets.only(left: 10),
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(img),
                      radius: 45,
                      backgroundColor: Colors.transparent,
                    ),
                    SizedBox(width: 20),
                    Text(username,
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 20,
                            fontWeight: FontWeight.bold))
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      height: 25,
                      width: 81,
                      child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(AppColors.pink1),
                          ),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true)
                                .push(MaterialPageRoute(
                                    builder: (context) => EditProfile(
                                          username: username,
                                          profilePicture: img,
                                        )));
                          },
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(fontSize: 10),
                          )),
                    ),
                    SizedBox(
                      height: 25,
                      width: 200,
                      child: TextField(
                        decoration: InputDecoration(
                            // border: ,
                            suffixIcon: Icon(
                          Icons.search,
                          color: Colors.black,
                          size: 20,
                        )),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        size: 20,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true)
                            .push(MaterialPageRoute(
                                builder: (context) => Settings(
                                      username: username,
                                      profilePicture: img,
                                      // userID: userid,
                                    )));
                      },
                    )
                  ],
                ),
                // SizedBox(
                //   height: 10,
                // ),
              ],
            )),
      ),
    );
  }
}

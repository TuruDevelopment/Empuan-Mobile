import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tumpuan/styles/style.dart';

class NavBar extends StatelessWidget {
  final int pageIndex;
  final Function(int) onTap;

  const NavBar({
    Key? key, // tambahkan Key? key di sini
    required this.pageIndex,
    required this.onTap,
  }) : super(key: key); // tambahkan ini juga

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);
    return Container(
      height: queryData.size.height / 10 - 18,
      color: Color.fromARGB(0, 0, 0, 0),
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: Platform.isAndroid ? 16 : 0,
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 0,
        elevation: 0.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 80, // ubah tinggi kontainer
            color: Color.fromRGBO(255, 255, 255, 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // tambahkan ini
              children: [
                navItem(
                  Icons.home_outlined,
                  'Home', // tambahkan teks di sini
                  pageIndex == 0,
                  onTap: () => onTap(0),
                ),
                navItem(
                  Icons.calendar_month,
                  'Catatan Haid', // tambahkan teks di sini
                  pageIndex == 1,
                  onTap: () => onTap(1),
                ),
                const SizedBox(width: 80),
                navItem(
                  Icons.call_outlined,
                  'Panggil Puan', // tambahkan teks di sini
                  pageIndex == 2,
                  onTap: () => onTap(2),
                ),
                navItem(
                  Icons.more_horiz,
                  'More', // tambahkan teks di sini
                  pageIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem(
    IconData icon,
    String text, // tambahkan parameter teks di sini
    bool selected, {
    Function()? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.pink1 : Colors.grey,
            ),
            SizedBox(height: 4), // tambahkan jarak di sini
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: selected ? AppColors.pink1 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

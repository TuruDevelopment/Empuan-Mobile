import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class CallView extends StatelessWidget {
  CallView({super.key, required this.name, required this.number});

  final String name;
  final String number;

  final player = AudioPlayer();

  Future<void> playSound() async {
    String soundPath = "ringtone.mp3";
    // await player.play(AssetSource(soundPath));
    player.play(AssetSource(soundPath));
  }

  Future<void> stopSound() async {
    player.stop();
  }

  @override
  Widget build(BuildContext context) {
    playSound();
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("images/bgQuiz.png"), fit: BoxFit.fill)),
        child: SafeArea(
          child: Column(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  Text(
                    name,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Satoshi',
                        fontSize: 50,
                        decoration: TextDecoration.none),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    number,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Satoshi',
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none),
                  )
                ],
              ),
              SizedBox(
                height: 420,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton(
                  style: ButtonStyle(
                      // iconSize: MaterialStatePropertyAll,
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.black12),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ))),
                  onPressed: () {
                    // Navigator.pop(context);
                    // await player.play(AssetSource('audios/ringtone.mp3'));
                    // await player.setSourceAsset('audios/ringtone.mp3');
                    // player.play;
                    // playSound();
                  },
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 50,
                  ),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      // iconSize: MaterialStatePropertyAll,
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.black12),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ))),
                  onPressed: () {
                    // Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.pause,
                    size: 50,
                  ),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      // iconSize: MaterialStatePropertyAll,
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.black12),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ))),
                  onPressed: () {
                    // Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.mic_off,
                    size: 50,
                  ),
                ),
              ]),
              SizedBox(height: 30),
              ElevatedButton(
                style: ButtonStyle(
                    // iconSize: MaterialStatePropertyAll,
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.red),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ))),
                onPressed: () {
                  stopSound();
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.call_end,
                  size: 50,
                ),
              ),
            ],
          ),
        ));
  }
}

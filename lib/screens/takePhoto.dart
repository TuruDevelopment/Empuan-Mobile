import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSelectionPage extends StatefulWidget {
  @override
  _ImageSelectionPageState createState() => _ImageSelectionPageState();
}

class _ImageSelectionPageState extends State<ImageSelectionPage> {
  File? _imageFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Image',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              if (_imageFile != null) {
                Navigator.pop(context, _imageFile);
              } else {
                // Show a snackbar if no image is selected
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No image selected'),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.check,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _imageFile == null
                  ? Text(
                      'No image selected.',
                      style: TextStyle(
                          fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
                    )
                  : Image.file(_imageFile!),
              SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(251, 111, 146, 1),
                ),
                onPressed: () => _getImage(ImageSource.camera),
                child: Text(
                  'Take Picture',
                  style: TextStyle(
                      fontFamily: 'Satoshi', fontWeight: FontWeight.bold,
                      color: Colors.white
                      ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(251, 111, 146, 1),
                ),
                onPressed: () => _getImage(ImageSource.gallery),
                child: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                      fontFamily: 'Satoshi', fontWeight: FontWeight.bold,
                      color: Colors.white
                      ),
                ),
              ),
              SizedBox(
                height: 30,
              )
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ImageSelectionPage(),
  ));
}

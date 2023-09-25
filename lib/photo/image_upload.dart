import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_recognition_app/model/photo.dart';
import 'package:image_recognition_app/photo/photo_page.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  // 画像をFirebase Storageにアップロードする関数
  Future<void> fileUpload() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      // Null check for pickedFile
      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final String timestamp = DateTime.now().toString();

        // Create storage reference
        final storageRef =
            FirebaseStorage.instance.ref().child('images/$timestamp');

        // Upload the file
        final TaskSnapshot uploadTaskSnapshot = await storageRef.putFile(file);

        // Once the upload is complete, then get the download URL
        final String imageUrl = await uploadTaskSnapshot.ref.getDownloadURL();

        // Add to Firestore
        final store = FirebaseFirestore.instance;
        final photo = Photo(title: timestamp, url: imageUrl);
        await store.collection('photos').add(photo.toJson());
      } else {
        print("No image selected.");
      }
    } catch (e) {
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Upload Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
                onPressed: () async {
                  await fileUpload();
                },
                icon: const Icon(Icons.upload)),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => PhotoPage()));
                },
                child: const Text('Photo Page')),
          ],
        ),
      ),
    );
  }
}

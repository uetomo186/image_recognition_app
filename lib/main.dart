import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_recognition_app/firebase_options.dart';
import 'package:image_recognition_app/photo/photo_upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Upload',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImageUploadScreen(),
    );
  }
}

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: ImageUploadScreen()));
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  final picker = ImagePicker();
  List<Face>? _faces;
  final FaceDetector faceDetector = FirebaseVision.instance.faceDetector();

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        debugPrint('No image selected.');
      }
    });

    detectFaces();
  }

  Future detectFaces() async {
    FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(_image!);
    List<Face> faces = await faceDetector.processImage(visionImage);

    setState(() {
      _faces = faces;
    });
  }

  Future uploadImageToFirebase(BuildContext context) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('uploads/$fileName');
    UploadTask uploadTask = ref.putFile(_image!);
    await uploadTask.whenComplete(() {
      debugPrint('ファイルがアップロードされました');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ファイルをアップロードできました')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像のアップロード'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null ? const Text('画像が選択されていません') : Image.file(_image!),
            if (_faces != null && _faces!.isNotEmpty)
              Text('検出された顔の数: ${_faces!.length}'),
            ElevatedButton(
              onPressed: getImage,
              child: const Text('画像を選択'),
            ),
            ElevatedButton(
              child: const Text('Firebaseにアップロードする'),
              onPressed: () => uploadImageToFirebase(context),
            ),
          ],
        ),
      ),
    );
  }
}

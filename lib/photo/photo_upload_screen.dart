import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(home: ImageUploadScreen()));
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({Key? key}) : super(key: key);

  @override
  ImageUploadScreenState createState() => ImageUploadScreenState();
}

class ImageUploadScreenState extends State<ImageUploadScreen> {
  List<File> _images = [];
  final picker = ImagePicker();
  String? _uploadedFileName;
  final dbRef = FirebaseDatabase.instance.ref();

  Future<void> getImage() async {
    final pickedFiles = await picker.pickMultiImage();

    setState(() {
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        _images = pickedFiles.map((file) => File(file.path)).toList();
      } else {
        debugPrint('No images selected.');
      }
    });
  }

  Future<void> detectFaces() async {
    if (_images.isEmpty) return;
    final inputImage = InputImage.fromFilePath(_images[0].path);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final List<Face> faces = await faceDetector.processImage(inputImage);
    for (Face face in faces) {
      final Rect bounds = face.boundingBox;
      // ここでboundsを使用して、顔の位置を取得したり、UI上で顔をハイライトしたりできます。
    }
    faceDetector.close();
  }

  Future uploadImageToFirebase(BuildContext context) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    _uploadedFileName = fileName;
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('uploads/$fileName');
    UploadTask uploadTask = ref.putFile(_images[0]); // ここでは最初の画像をアップロードします。
    await uploadTask.whenComplete(() async {
      debugPrint('ファイルがアップロードされました');
      String imageUrl = await ref.getDownloadURL();
      dbRef.child('uploaded_images/$fileName').set(imageUrl);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ファイルをアップロードできました')));
    });
  }

  Future fetchImagesFromDatabase() async {
    DatabaseEvent event = await dbRef.child('uploaded_images').once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      Map<String, String> imagesMap =
          Map<String, String>.from(snapshot.value as Map);
      List<String> urls = List<String>.from(imagesMap.values);
      setState(() {
        _imageUrls = urls;
      });
      saveImageUrlsToPrefs();
    }
  }

  List<String> _imageUrls = [];

  Future<void> saveImageUrlsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('imageUrls', jsonEncode(_imageUrls));
  }

  Future<void> loadImageUrlsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('imageUrls');
    if (jsonString != null) {
      _imageUrls = List<String>.from(jsonDecode(jsonString));
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadImageUrlsFromPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写真一覧'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _images.isEmpty
                  ? const Text('画像が選択されていません')
                  : Image.file(_images[0]), // ここでは最初の画像を表示します。
              ElevatedButton(
                onPressed: getImage,
                child: const Text('画像を選択'),
              ),
              ElevatedButton(
                child: const Text('Firebaseにアップロードする'),
                onPressed: () => uploadImageToFirebase(context),
              ),
              ElevatedButton(
                onPressed: fetchImagesFromDatabase,
                child: const Text('Databaseから画像のURLを取得する'),
              ),
              SizedBox(
                height: 400,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                  itemCount: _imageUrls.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Image.network(_imageUrls[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
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
  List<Face> detectedFaces = [];
  final dbRef = FirebaseDatabase.instance.ref();

  Future<void> getImage() async {
    final pickedFiles = await picker.pickMultiImage();
    // 画像を選択したら顔検出を実行
    await detectFaces();
    setState(() {
      if (pickedFiles.length <= 4) {
        _images = pickedFiles.map((file) => File(file.path)).toList();
      } else if (pickedFiles.length > 4) {
        _images = pickedFiles.take(4).map((file) => File(file.path)).toList();
        debugPrint('最大4枚の画像を選択できます。最初の4枚のみが選択されました。');
      } else {
        debugPrint('画像が選択されていません');
      }
    });
  }

  Future<void> detectFaces() async {
    if (_images.isEmpty) return;
    final inputImage = InputImage.fromFilePath(_images[0].path);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final List<Face> faces = await faceDetector.processImage(inputImage);
    setState(() {
      detectedFaces = faces;
    });
    faceDetector.close();
  }

  Future uploadImageToFirebase(BuildContext context) async {
    for (var image in _images) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      _uploadedFileName = fileName;
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('uploads/$fileName');
      UploadTask uploadTask = ref.putFile(image); // 全ての画像をアップロードします。
      await uploadTask.whenComplete(() async {
        debugPrint('ファイルがアップロードされました');
        String imageUrl = await ref.getDownloadURL();
        dbRef.child('uploaded_images/$fileName').set(imageUrl);
      });
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('全てのファイルをアップロードできました')));
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
                  : Wrap(
                      spacing: 8.0, // 画像の間にスペースを追加する場合
                      children: _images.map((image) {
                        return Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(image),
                              fit: BoxFit.cover, // 画像をコンテナの大きさに合わせて調整します
                            ),
                            borderRadius:
                                BorderRadius.circular(8.0), // 画像の角を丸める場合
                          ),
                        );
                      }).toList()),
              ElevatedButton(
                onPressed: getImage,
                child: const Text('画像を選択'),
              ),
              ElevatedButton(
                child: const Text('画像をアップロードする'),
                onPressed: () => uploadImageToFirebase(context),
              ),
              ElevatedButton(
                onPressed: fetchImagesFromDatabase,
                child: const Text('画像を取得する'),
              ),
              SizedBox(
                height: 400,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                  ),
                  itemCount: _imageUrls.length,
                  itemBuilder: (BuildContext context, int index) {
                    return PhotoView(
                      imageProvider: NetworkImage(_imageUrls[index]),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                      backgroundDecoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      heroAttributes:
                          PhotoViewHeroAttributes(tag: 'image$index'),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFaceHighlights() {
    // この例では、顔の周りに矩形を表示します。実際には、検出された顔の情報に基づいてカスタマイズすることができます。
    return detectedFaces.map((face) {
      return Positioned(
        left: face.boundingBox.left,
        top: face.boundingBox.top,
        child: Container(
          width: face.boundingBox.width,
          height: face.boundingBox.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red,
              width: 2.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}

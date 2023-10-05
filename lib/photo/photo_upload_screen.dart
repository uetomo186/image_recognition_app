import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_recognition_app/widget/image_zoom.dart';
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
                      spacing: 8.0,
                      children: _images.map((image) {
                        return Stack(
                          children: [
                            Container(
                              width: 100.0,
                              height: 100.0,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: FileImage(image),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            ..._buildFaceHighlights(), // こちらで顔のハイライトを追加します
                          ],
                        );
                      }).toList(),
                    ),
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
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ImageUploadScreen(),
                          ),
                        );
                      },
                      child:
                          Image.network(_imageUrls[index], fit: BoxFit.cover),
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

// 顔をハイライト表示するウィジェットのメソッド
  List<Widget> _buildFaceHighlights() {
    return detectedFaces.map((face) {
      return GestureDetector(
        onTap: () async {
          // ダイアログを表示し、ユーザーに名前を入力させる
          final enteredName = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              String tempName = '';
              return AlertDialog(
                title: const Text('名前を入力してください'),
                content: TextField(
                  onChanged: (value) => tempName = value,
                ),
                actions: [
                  ElevatedButton(
                    child: const Text('確定'),
                    onPressed: () => Navigator.of(context).pop(tempName),
                  ),
                  ElevatedButton(
                    child: const Text('キャンセル'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );

          if (enteredName != null && enteredName.isNotEmpty) {
            // 名前と顔の情報を関連付ける処理
            associateNameWithFace(enteredName, face);
          }
        },
      );
    }).toList();
  }

  // 名前と顔の情報を関連付ける処理
  void associateNameWithFace(String name, Face face) {
    // このメソッド内で、名前と顔の情報（特徴量やIDなど）を関連付けて保存する処理を実装します。
    // 例: データベースやSharedPreferencesを使用するなど。
  }
}

Future<Uint8List?> downloadImageFromFirebase(String filePath) async {
  FirebaseStorage storage = FirebaseStorage.instance;
  Reference ref = storage.ref(filePath);
  try {
    final data = await ref.getData();
    return data;
  } catch (e) {
    print('Error downloading image from Firebase: $e');
    return null;
  }
}

Future<List?> applyModelOnImage(Uint8List imageData) async {
  const outputSize = 100; // 例としての値。実際のモデルの出力サイズに応じて変更する必要があります。

  // 画像データの前処理（例としての単純化、実際にはモデルの要件に合わせて調整する必要があります）
  // ...

  // tflite_flutterを使用してモデルに画像データを適用
  try {
    final interpreter = await Interpreter.fromAsset('your_model.tflite');
    var output = List<double>.filled(outputSize, 0);
    interpreter.run(imageData, output);
    return output;
  } catch (e) {
    debugPrint('Error running TFLite model: $e');
    return null;
  }
}

void processImageFromFirebase(String filePath) async {
  final imageData = await downloadImageFromFirebase(filePath);
  if (imageData != null) {
    final predictions = await applyModelOnImage(imageData);
    if (predictions != null) {
      // predictionsを使用して必要な処理を行う
      // ...
    }
  }
}

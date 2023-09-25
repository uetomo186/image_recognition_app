import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(home: ImageUploadScreen()));
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({Key? key}) : super(key: key); // super.key を修正しました

  @override
  ImageUploadScreenState createState() => ImageUploadScreenState();
}

class ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  final picker = ImagePicker();
  String? _downloadedImageUrl;
  String? _uploadedFileName;

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        debugPrint('No image selected.');
      }
    });
  }

  Future uploadImageToFirebase(BuildContext context) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    _uploadedFileName = fileName;
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('uploads/$fileName');
    UploadTask uploadTask = ref.putFile(_image!);
    await uploadTask.whenComplete(() async {
      debugPrint('ファイルがアップロードされました');

      // URL を取得して Firestore に保存
      String imageUrl = await ref.getDownloadURL();
      FirebaseFirestore.instance.collection('uploaded_images').add({
        'url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ファイルをアップロードできました')));
    });
  }

  Future<String?> _getImageUrlFromFirebaseStorage(String fileName) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('uploads/$fileName');
    try {
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("画像の取得中にエラーが発生しました: $e");
      return null;
    }
  }

  List<String> _imageUrls = [];

  Future fetchImagesFromFirestore() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('uploaded_images')
        .orderBy('timestamp', descending: true)
        .get();

    List<String> urls =
        snapshot.docs.map((doc) => doc['url'] as String).toList();
    setState(() {
      _imageUrls = urls;
    });
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
              _image == null ? const Text('画像が選択されていません') : Image.file(_image!),
              ElevatedButton(
                onPressed: getImage,
                child: const Text('画像を選択'),
              ),
              ElevatedButton(
                child: const Text('Firebaseにアップロードする'),
                onPressed: () => uploadImageToFirebase(context),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_uploadedFileName != null) {
                    String? imageUrl = await _getImageUrlFromFirebaseStorage(
                        _uploadedFileName!);
                    setState(() {
                      _downloadedImageUrl = imageUrl;
                    });
                  } else {
                    debugPrint('アップロードされたファイルがまだありません');
                  }
                },
                child: const Text('Firebaseから画像を取得する'),
              ),
              if (_downloadedImageUrl != null)
                Image.network(_downloadedImageUrl!)
              else
                const Text('画像がまだありません'),
              SizedBox(
                height: 300, // ここで適切な高さを設定します。
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
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

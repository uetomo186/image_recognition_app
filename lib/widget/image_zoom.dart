import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaceRecognitionScreen extends StatefulWidget {
  final String imageUrl;

  const FaceRecognitionScreen({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  String? _result;
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    _analyzeImage(widget.imageUrl); // 画像解析を初期化時に実行
  }

  Future<Uint8List?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        _imageData = response.bodyBytes;
        return response.bodyBytes;
      } else {
        debugPrint('Firebaseから画像をロードできませんでした');
        return null;
      }
    } catch (e) {
      debugPrint('エラー: $e');
      return null;
    }
  }

  Future<void> _analyzeImage(String imageUrl) async {
    final imageBytes = await _downloadImage(imageUrl);
    if (imageBytes == null) return;
    final image = img.decodeImage(imageBytes);

    final output =
        List.filled(1, Float32List(5 * 1 * 1 * 128), growable: false);
    setState(() {
      _result = output.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: ListView(
        children: [
          if (_imageData != null)
            Image.memory(_imageData!)
          else
            const Center(child: CircularProgressIndicator()),
          if (_result != null) Text('Result: $_result'),
        ],
      ),
    );
  }
}

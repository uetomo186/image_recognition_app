import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_recognition_app/photo/camera_view.dart';

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({super.key});

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  // ①FaceDetectorのインスタンスを作成
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  String? _text;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
    );
  }

  // ②顔検出処理のための関数
  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    // ③processImage関数に画像を渡す
    final faces = await _faceDetector.processImage(inputImage);
    // ④検出された顔の数を取得
    String text = '検出された顔の数: ${faces.length}\n\n';

    // ⑤検出された顔の笑顔度(smilingProbability)を取得
    for (final face in faces) {
      text +=
          'smilingProbabilityの値: ${(face.smilingProbability! * 100).floor()}%\n\n';
      _text = text;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}

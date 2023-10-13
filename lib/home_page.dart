import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:image_recognition_app/photo/camera_view.dart';
import 'package:image_recognition_app/photo/photo_page.dart';
import 'package:image_recognition_app/photo/photo_upload_screen.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("写真一覧",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/vector.svg'),
                  const SizedBox(width: 8),
                  const Text('お気に入り',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text(
                  'フォルダを新規作成',
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ImageUploadScreen()));
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text(
                  '画像を認識する',
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CameraView(
                                onImage: (InputImage inputImage) {},
                              )));
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text(
                  'フォトページフォルダを新規作成',
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PhotoPage()));
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(
                  'カメラスクリーン',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ImageUploadScreen()));
                },
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}

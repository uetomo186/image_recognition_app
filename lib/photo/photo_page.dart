import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_recognition_app/model/photo.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class PhotoPage extends StatefulWidget {
  const PhotoPage({Key? key}) : super(key: key);

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Photo Page'),
      ),
      // モデルクラスPhotoを使い画像を表示する
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('photos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<Photo> photos = snapshot.data!.docs
                .map(
                    (doc) => Photo.fromJson(doc.data() as Map<String, dynamic>))
                .toList();
            return ListView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  trailing: IconButton(
                    onPressed: () async {
                      try {
                        final response =
                            await http.get(Uri.parse(photos[index].url));
                        print('HTTP Status Code: ${response.statusCode}');

                        if (response.statusCode != 200) {
                          print('Failed to get image: ${response.statusCode}');
                          return;
                        }

                        final bytes = response.bodyBytes;
                        if (bytes.isEmpty) {
                          print('Empty response');
                          return;
                        }

                        await Share.shareXFiles(
                          [
                            XFile.fromData(bytes,
                                name: 'image.jpeg', // 画像の名前
                                mimeType: 'image/jpeg' // 画像の形式
                                )
                          ],
                        );
                      } catch (e) {
                        print('An error occurred: $e');
                      }
                    },
                    icon: const Icon(Icons.share),
                  ),
                  title: Text(photos[index].title),
                  leading: Image.network(photos[index].url),
                );
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

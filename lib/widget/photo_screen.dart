import 'package:flutter/material.dart';

class PhotosScreen extends StatelessWidget {
  final Map<String, List<String>> faceImages = {
    'Person 1': ['image1.jpg', 'image2.jpg', 'image3.jpg'],
    'Person 2': ['image4.jpg', 'image5.jpg'],
    // ... (他の人々の写真を追加)
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Photos UI Clone')),
      body: ListView.builder(
        itemCount: faceImages.keys.length,
        itemBuilder: (context, index) {
          String faceName = faceImages.keys.elementAt(index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  faceName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: faceImages[faceName]!.length,
                  itemBuilder: (context, imgIndex) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(faceImages[faceName]![imgIndex]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

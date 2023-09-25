class Photo {
  final String title;
  final String url;

  const Photo({required this.title, required this.url});
  // from Jsonでデータをシリアライズ(Dartのオブジェクトに変換)する
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }
  // toJsonでデータをデシリアライズ(Jsonに変換)する
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
    };
  }
}

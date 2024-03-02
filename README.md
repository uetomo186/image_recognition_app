## 顔認証機能アプリまとめ

写真のアルバム機能を実装する場合は、Firebase Storage を使用して画像を投稿できるように実装していく。
Firebase Storage に画像を顔認識で読み込む処理が必要かと考える。

- カメラ機能を実装するために参考にした記事
  https://zenn.dev/mamushi/articles/flutter_camera

- Teachable Machine と連携して画像の識別の実施することも可能
  https://teachablemachine.withgoogle.com/

- ネイティブで顔の識別を実装している参考記事
  https://techblog.timers-inc.com/entry/2020/04/24/143803

- Google MlKit 関連
  https://pub.dev/packages/google_ml_kit
  https://pub.dev/documentation/google_mlkit_face_detection/latest/google_mlkit_face_detection/Face-class.html

https://developers.google.com/ml-kit/vision/face-detection?hl=ja


## flutter の ML Kit で顔認証について可能なこと

- 顔の検出:
  写真や動画フレーム内の顔の位置を検出します。
- 顔の輪郭の検出:
  顔の主要な部位（目、耳、鼻、口、眉など）の輪郭を検出することができます。
- 顔のランドマーク検出:
  顔の特定の点、例えば目の位置や鼻の先、口の端などを特定できます。
- 顔の向きの検出:
  顔が上を向いているか、下を向いているか、左右どちらを向いているかなど、顔の向きを検出できます。
- 表情の検出:
  顔の特徴から、笑顔や驚きなどの表情を認識することができる機能もあります（ただし、これは感情分析とは異なり、具体的な感情を示すものではありません）。
- 目の開閉検出:
  人が目を開いているか閉じているかを検出できます。
- 口の開閉検出:
  口が開いているか閉じているかを認識することができます。
- 顔の追跡:
  動画フレーム間での顔の動きを追跡することができます。これは、動画の連続的なフレームで顔を追跡する場合に役立ちます。
- 複数の顔の検出:
  一つの写真や動画フレーム内に存在する複数の顔を検出することができます。
  → こちらの機能を使用することにより、顔認識のツールが作成できそうです。
  

## Flutter 

- Flutter だけで顔認証アプリを完全に実装することは難しいかもしれません。
  そもそも公式で Flutter 独自の API が用意されていないためです。
- Flutter ではカメラを起動した際の顔を認識する動作は備わっていますが、Firebase に保存している画像を読み込んで顔を認識する場合はネイディブのコードを修正して実装する必要があると考えられます。
- そのため、Flutter で顔認証アプリを実装する場合は、ネイティブのコードを修正して実装する必要があると考えられます。
  以下参考記事
  https://developers.google.com/ml-kit/vision/face-detection?hl=ja

  <img width="896" alt="image2023-10-20 18 37 04" src="https://github.com/uehoho18/image_recognition_app/assets/57786349/47719ed9-0082-4adc-a0db-7f9834028b47">


## 家族アプリ Famm は FirebaeML Kit を使用して実装していたが、現在は非推奨になっているおり、使用できなくなっている

Firebase ML の AutoML Vision Edge 機能は非推奨になりました。Vertex AI を使用して ML モデルを自動でトレーニングすることを検討してください。この ML モデルは、TensorFlow Lite モデルとしてエクスポートしてデバイス上で使用することもでき、クラウドベースの推論用としてデプロイすることもできる。


## 顔検出のモデルには Google Cloud Vision AI API を使用する

クラウドベースの API で、写真や動画から顔を検出することができます。
他の多くの画像分析機能（ラベル検出、テキスト検出、オブジェクト検出など）も提供しています。

- サーバー側で画像認識機能を作成して API を利用して実装が必要になってくると思われます。
  https://cloud.google.com/vision/automl/docs/create-datasets?hl=ja
  https://developers.google.com/ml-kit/vision/face-detection?hl=ja


- 試せなかったのですが、機械学習モデルについてはこちらのドキュメントである程度は画像の機械学習ができそうかと思います。
  https://cloud.google.com/vision/automl/docs/create-datasets?hl=ja
  https://cloud.google.com/vision/?hl=ja&_ga=2.231762909.-31886449.1695347274

  

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'const.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PixabayPage(),
    );
  }
}
class PixabayPage extends StatefulWidget {
  const PixabayPage({super.key});
  
  @override
  State<PixabayPage> createState() => _PixabayPageState();
}

class _PixabayPageState extends State<PixabayPage> {
  List<PixabayImage> PixabayImages = [];
  // 非同期の関数になったため返り値にFutureがつき、さらに async　キーワードが追加
  Future<void> fetchImages(String text) async{
    // awaitで待つことでFutureが外れ Response　型のデータを受け取ることができました。
    final response= await Dio().get(
      'https://pixabay.com/api/',
      queryParameters: {
        'key': APIKey,
        'q': text,
        'image_type': 'photo',
        'pretty': 'true',
        'per_page': '100',
      },
      );
    print(response.data);
    // この時点では要素の中身の型はMap<String, dynamic>
    final List hits = response.data['hits'];
    // Mapメソッドを使ってMap<string,dynamic>の型を一つ一つPixabayimage　型に変換していく
    PixabayImages = hits.map((e) => PixabayImage.fromMap(e)).toList();
    // 画面の再更新
    setState(() {});
  }
  Future<void> shareImage(String url) async{
    // 一時保存で使用できるフォルダ情報を取得
    // Future型なのでawaitで待つ
    final dir =await getTemporaryDirectory();

    final response =await Dio().get(
      // previewURLは荒いので高解像度のwebformatURLから画像をダウンロード
      url,
      options: Options(
        // 画像データをダウンロードするときはResponseType.bytes　を指定
        responseType: ResponseType.bytes,
      )
    );
    // フォルダの中にimage.pngという名前でファイルを作り、そこに画像データを書き込みます。
    final imageFile =await File('${dir.path}/image.png').writeAsBytes(response.data);
    // pathを指定するとshareできる
    await Share.shareFiles([imageFile.path]);
  }
  // この関数の中の処理は初回に一回だけ実行されます
  @override
  void initState() {
    super.initState();
    // 最初に一度だけ画像データを取得します。
    fetchImages('花');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          decoration: const InputDecoration(
            fillColor: Colors.white,
            filled: true,
          ),
          // 文字列の入力が完了したら実行。textは用意されている変数
          onFieldSubmitted: (text){
            print(text);
            fetchImages(text);
          },
        ),
      ),
      body: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            // 横に並べる個数を決める
            crossAxisCount: 3,
            ),
          // itemCountには要素数を与える。
          // Listの要素数を取得
          itemCount: PixabayImages.length,
          itemBuilder: (context,index){
            // 要素を順番に取り出す
            final pixabayImage = PixabayImages[index];
            return 
            InkWell(
              onTap: () async{
                shareImage(pixabayImage.webformatURL);
              },
              child: Stack(
                // StackFit.expandは領域いっぱいに広がる
                //  fit: StackFit.expand,
                children: [
                  Image.network(
                    pixabayImage.previewURL,
                    fit: BoxFit.cover,
                    ),
                    Align(
                      // 左上ではなく右上に表示されるようにする
                      alignment: Alignment.bottomRight,
                      child: Container(
                        color: Colors.white,
                        child: Row(
                          // MainAxisSize.minは必要最小限のサイズに縮小
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.thumb_up_alt_outlined,
                              size: 14,
                            ),
                            Text('${pixabayImage.likes}'),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    color: Colors.white,
                    // likes keyのvalueからいいね数を取り出す
                    child: Text('${pixabayImage.likes}'),
                  )
                ],
              ),
            );
          }
         ),
    );
  }
}
class PixabayImage {
  final String previewURL;
  final int likes;
  final String webformatURL;

  PixabayImage({
    required this.previewURL,
    required this.likes,
    required this.webformatURL,
  });

  factory PixabayImage.fromMap(Map<String, dynamic> map){
    return PixabayImage(
      previewURL: map['previewURL'],
      likes: map['likes'],
      webformatURL: map['webformatURL'],
    );
  }
}
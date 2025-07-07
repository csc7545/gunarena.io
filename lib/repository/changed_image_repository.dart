import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ChangedImageRepository {
  static final ChangedImageRepository instance =
      ChangedImageRepository._internal();
  factory ChangedImageRepository() => instance;
  ChangedImageRepository._internal();

  Future<String?> fetchImage({required int pageNo}) async {
    try {
      http.Response response = await http.get(
        Uri.parse("https://picsum.photos/v2/list?page=$pageNo&limit=1"),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          String? url = data[0]["download_url"];
          return url;
        } else {
          return null;
        }
      }
      return null;
    } on HttpException catch (error) {
      return null;
    }
  }
}

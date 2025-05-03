import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MLService {
  final String apiUrl = 'https://dog-breed-recognition-android-app.onrender.com/predict'; // înlocuiește cu IP-ul PC-ului în rețea

  Future<Map<String, dynamic>?> predictBreed(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Prediction error: $e');
      return null;
    }
  }
}
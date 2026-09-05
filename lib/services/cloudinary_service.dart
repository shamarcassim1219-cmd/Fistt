import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Replace with your actual Cloudinary cloud name (confirm from Dashboard).
  static const String cloudName = 'au5lojti';
  static const String uploadPreset = 'mygame_upload';

  static Future<String> uploadImage(File imageFile, {String folder = 'mygame'}) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${response.statusCode}): $resBody');
    }

    final data = jsonDecode(resBody);
    return data['secure_url'] as String;
  }
}

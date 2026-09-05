static Future<String> uploadImage(File file) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final ext = file.path.split('.').last.toLowerCase();
    final mimeType = (ext == 'png') ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('image', mimeType),
    ));

    final streamedRes = await request.send();
    final resBody = await streamedRes.stream.bytesToString();

    if (streamedRes.statusCode != 200) {
      final err = jsonDecode(resBody);
      throw Exception(err['error'] ?? 'Upload failed (${streamedRes.statusCode})');
    }
    final data = jsonDecode(resBody);
    return data['url'];
  }

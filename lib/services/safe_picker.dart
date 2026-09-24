import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies a picked image into the app's own storage right away.
/// The phone can delete files in the cache folder at any time (that caused
/// "PathNotFound ... cache/scaled_....jpg" when submitting later).
Future<XFile> _keepPickedImage(XFile img) async {
  try {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/picked');
    if (!await dir.exists()) await dir.create(recursive: true);

    // remove old copies (older than 2 days) so the folder does not grow forever
    final cutoff = DateTime.now().subtract(const Duration(days: 2));
    await for (final e in dir.list()) {
      if (e is File) {
        try {
          if (e.lastModifiedSync().isBefore(cutoff)) e.deleteSync();
        } catch (_) {}
      }
    }

    final name = img.name.isEmpty ? 'image.jpg' : img.name;
    final dest = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}_$name';
    await File(img.path).copy(dest);
    return XFile(dest, name: name);
  } catch (_) {
    return img; // could not copy, use the original
  }
}

extension SafeImagePicker on ImagePicker {
  Future<XFile?> pickImageSafe({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final img = await pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      preferredCameraDevice: preferredCameraDevice,
    );
    if (img == null) return null;
    return _keepPickedImage(img);
  }

  Future<List<XFile>> pickMultiImageSafe({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final list = await pickMultiImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    final out = <XFile>[];
    for (final img in list) {
      out.add(await _keepPickedImage(img));
    }
    return out;
  }
}

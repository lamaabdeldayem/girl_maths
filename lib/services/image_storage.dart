// lib/services/image_storage.dart
//
// Image picker (Lecture 5, part 4): pick from camera / gallery and copy the
// file into the app documents directory so it survives cache clean-ups.
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorage {
  ImageStorage._();

  static final ImagePicker _picker = ImagePicker();

  /// Returns the saved local path, or null if the user cancelled.
  static Future<String?> pickAndSave(ImageSource source,
      {String prefix = 'img'}) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final saved = await File(picked.path).copy(p.join(imagesDir.path, fileName));
    return saved.path;
  }

  /// Deletes an image we own (when an expense/goal is deleted or the image
  /// is replaced).
  static Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static bool exists(String? path) =>
      path != null && path.isNotEmpty && File(path).existsSync();
}

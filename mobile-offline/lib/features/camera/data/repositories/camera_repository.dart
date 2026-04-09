import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/database_service.dart';
import '../../../../services/thumbnail_service.dart';
import '../../domain/entities/photo.dart';

class CameraRepository {
  final ImagePicker _imagePicker;
  final _uuid = const Uuid();

  CameraRepository() : _imagePicker = ImagePicker();

  Future<String?> importFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 95,
    );
    return pickedFile?.path;
  }

  Future<Photo> savePhoto(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(directory.path, 'daiary', 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final id = _uuid.v4();
    final extension = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final fileName = '$id$extension';
    final destPath = p.join(photosDir.path, fileName);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);

    // Get file info
    final fileSize = await File(destPath).length();
    final originalFilename = p.basename(sourcePath);

    // Generate thumbnail
    String? thumbnailPath;
    try {
      thumbnailPath = await ThumbnailService.generateThumbnail(destPath);
    } catch (_) {
      // Continue without thumbnail
    }

    // Create photo record
    final now = DateTime.now();
    final photo = Photo(
      id: id,
      localPath: destPath,
      thumbnailPath: thumbnailPath,
      originalFilename: originalFilename,
      fileSize: fileSize,
      createdAt: now,
    );

    // Save to database
    final db = await DatabaseService.database;
    await db.insert('photos', photo.toMap());

    return photo;
  }
}

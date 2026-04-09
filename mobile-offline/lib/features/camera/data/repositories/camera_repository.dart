import 'dart:io';
import 'dart:ui' as ui;
import 'package:exif/exif.dart';
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
    final destFile = File(destPath);
    final fileSize = await destFile.length();
    final originalFilename = p.basename(sourcePath);

    // Extract EXIF data
    Map<String, dynamic>? exifData;
    try {
      final bytes = await destFile.readAsBytes();
      final tags = await readExifFromBytes(bytes);
      if (tags.isNotEmpty) {
        final exifMap = <String, dynamic>{};
        for (final entry in tags.entries) {
          exifMap[entry.key] = entry.value.toString();
        }
        exifData = exifMap;
      }
    } catch (_) {
      // Continue without EXIF data
    }

    // Get image dimensions using dart:ui (lightweight, header-only decode)
    int? width;
    int? height;
    try {
      final bytes = await destFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      width = frame.image.width;
      height = frame.image.height;
      frame.image.dispose();
    } catch (_) {
      // Continue without dimensions
    }

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
      width: width,
      height: height,
      exifData: exifData,
      createdAt: now,
    );

    // Save to database
    final db = await DatabaseService.database;
    await db.insert('photos', photo.toMap());

    return photo;
  }
}

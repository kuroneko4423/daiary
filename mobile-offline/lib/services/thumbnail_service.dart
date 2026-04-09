import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ThumbnailService {
  static const int thumbnailWidth = 300;
  static const int thumbnailHeight = 300;

  static Future<String> generateThumbnail(String originalPath) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final thumbDir =
        Directory(p.join(documentsDir.path, 'daiary', 'thumbnails'));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }

    final originalFile = File(originalPath);
    final bytes = await originalFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image: $originalPath');
    }

    final thumbnail = img.copyResize(
      image,
      width: thumbnailWidth,
      height: thumbnailHeight,
      maintainAspect: true,
    );

    final baseName = p.basenameWithoutExtension(originalPath);
    final thumbPath = p.join(thumbDir.path, '${baseName}_thumb.jpg');
    final thumbFile = File(thumbPath);
    await thumbFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 80));

    return thumbPath;
  }
}

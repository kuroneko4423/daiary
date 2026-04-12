import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageUsage {
  final int photosBytes;
  final int thumbnailsBytes;
  final int totalBytes;

  const StorageUsage({
    this.photosBytes = 0,
    this.thumbnailsBytes = 0,
    this.totalBytes = 0,
  });
}

Future<int> _directorySize(Directory dir) async {
  int total = 0;
  if (!await dir.exists()) return 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) {
      total += await entity.length();
    }
  }
  return total;
}

final storageUsageProvider = FutureProvider<StorageUsage>((ref) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final photosDir =
      Directory(p.join(documentsDir.path, 'daiary', 'photos'));
  final thumbsDir =
      Directory(p.join(documentsDir.path, 'daiary', 'thumbnails'));

  final photosBytes = await _directorySize(photosDir);
  final thumbnailsBytes = await _directorySize(thumbsDir);

  return StorageUsage(
    photosBytes: photosBytes,
    thumbnailsBytes: thumbnailsBytes,
    totalBytes: photosBytes + thumbnailsBytes,
  );
});

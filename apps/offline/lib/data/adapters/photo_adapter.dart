import 'dart:convert';
import 'package:daiary_shared/domain/models/photo.dart';

// SQLite 用の Photo シリアライズ
Photo photoFromMap(Map<String, dynamic> map) {
  return Photo(
    id: map['id'] as String,
    localPath: map['local_path'] as String,
    thumbnailPath: map['thumbnail_path'] as String?,
    originalFilename: map['original_filename'] as String?,
    fileSize: map['file_size'] as int?,
    width: map['width'] as int?,
    height: map['height'] as int?,
    exifData: map['exif_data'] != null
        ? Map<String, dynamic>.from(
            jsonDecode(map['exif_data'] as String) as Map)
        : null,
    aiTags: map['ai_tags'] != null
        ? (map['ai_tags'] as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList()
        : null,
    isFavorite: (map['is_favorite'] as int?) == 1,
    deletedAt: map['deleted_at'] != null
        ? DateTime.parse(map['deleted_at'] as String)
        : null,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

Map<String, dynamic> photoToMap(Photo photo) {
  return {
    'id': photo.id,
    'local_path': photo.localPath,
    'thumbnail_path': photo.thumbnailPath,
    'original_filename': photo.originalFilename,
    'file_size': photo.fileSize,
    'width': photo.width,
    'height': photo.height,
    'exif_data': photo.exifData != null ? jsonEncode(photo.exifData) : null,
    'ai_tags': photo.aiTags?.join(','),
    'is_favorite': photo.isFavorite ? 1 : 0,
    'deleted_at': photo.deletedAt?.toIso8601String(),
    'created_at': photo.createdAt.toIso8601String(),
  };
}

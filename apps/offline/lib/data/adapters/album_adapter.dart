import 'package:daiary_shared/domain/models/album.dart';

// SQLite 用の Album シリアライズ
Album albumFromMap(Map<String, dynamic> map) {
  return Album(
    id: map['id'] as String,
    name: map['name'] as String,
    coverPhotoId: map['cover_photo_id'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}

Map<String, dynamic> albumToMap(Album album) {
  return {
    'id': album.id,
    'name': album.name,
    'cover_photo_id': album.coverPhotoId,
    'created_at': album.createdAt.toIso8601String(),
    'updated_at': album.updatedAt.toIso8601String(),
  };
}

import '../../domain/entities/album.dart';

class AlbumModel extends Album {
  const AlbumModel({
    required super.id,
    required super.userId,
    required super.name,
    super.coverPhotoId,
    super.isPublic,
    super.shareToken,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      coverPhotoId: json['cover_photo_id'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      shareToken: json['share_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

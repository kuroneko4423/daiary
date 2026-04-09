class Album {
  final String id;
  final String name;
  final String? coverPhotoId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Album({
    required this.id,
    required this.name,
    this.coverPhotoId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'] as String,
      name: map['name'] as String,
      coverPhotoId: map['cover_photo_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cover_photo_id': coverPhotoId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

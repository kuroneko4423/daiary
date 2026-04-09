class Photo {
  final String id;
  final String localPath;
  final String? thumbnailPath;
  final String? originalFilename;
  final int? fileSize;
  final int? width;
  final int? height;
  final Map<String, dynamic>? exifData;
  final List<String>? aiTags;
  final bool isFavorite;
  final DateTime? deletedAt;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.localPath,
    this.thumbnailPath,
    this.originalFilename,
    this.fileSize,
    this.width,
    this.height,
    this.exifData,
    this.aiTags,
    this.isFavorite = false,
    this.deletedAt,
    required this.createdAt,
  });

  Photo copyWith({
    String? localPath,
    String? thumbnailPath,
    String? originalFilename,
    int? fileSize,
    int? width,
    int? height,
    Map<String, dynamic>? exifData,
    List<String>? aiTags,
    bool? isFavorite,
    DateTime? deletedAt,
  }) {
    return Photo(
      id: id,
      localPath: localPath ?? this.localPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      originalFilename: originalFilename ?? this.originalFilename,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      exifData: exifData ?? this.exifData,
      aiTags: aiTags ?? this.aiTags,
      isFavorite: isFavorite ?? this.isFavorite,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
    );
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as String,
      localPath: map['local_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      originalFilename: map['original_filename'] as String?,
      fileSize: map['file_size'] as int?,
      width: map['width'] as int?,
      height: map['height'] as int?,
      aiTags: map['ai_tags'] != null
          ? (map['ai_tags'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : null,
      isFavorite: (map['is_favorite'] as int?) == 1,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'local_path': localPath,
      'thumbnail_path': thumbnailPath,
      'original_filename': originalFilename,
      'file_size': fileSize,
      'width': width,
      'height': height,
      'ai_tags': aiTags?.join(','),
      'is_favorite': isFavorite ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

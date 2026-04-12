class Photo {
  final String id;
  final String? userId;
  final String? storagePath;
  final String? localPath;
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
    this.userId,
    this.storagePath,
    this.localPath,
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

  /// Returns the path to display/access the image.
  /// Offline: localPath, Online: storagePath.
  String get imagePath => localPath ?? storagePath ?? '';

  Photo copyWith({
    String? userId,
    String? storagePath,
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
      userId: userId ?? this.userId,
      storagePath: storagePath ?? this.storagePath,
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
}

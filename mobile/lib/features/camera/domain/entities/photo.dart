class Photo {
  final String id;
  final String userId;
  final String storagePath;
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
    required this.userId,
    required this.storagePath,
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
}

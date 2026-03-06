class Album {
  final String id;
  final String userId;
  final String name;
  final String? coverPhotoId;
  final bool isPublic;
  final String? shareToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Album({
    required this.id,
    required this.userId,
    required this.name,
    this.coverPhotoId,
    this.isPublic = false,
    this.shareToken,
    required this.createdAt,
    required this.updatedAt,
  });
}

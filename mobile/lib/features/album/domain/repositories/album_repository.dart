import '../entities/album.dart';

abstract class AlbumRepository {
  Future<List<Album>> getAlbums();
  Future<Album> getAlbum(String id);
  Future<Album> createAlbum({required String name, String? coverPhotoId});
  Future<Album> updateAlbum(String id, {String? name, String? coverPhotoId, bool? isPublic});
  Future<void> deleteAlbum(String id);
  Future<void> addPhotosToAlbum(String albumId, List<String> photoIds);
  Future<void> removePhotoFromAlbum(String albumId, String photoId);
}

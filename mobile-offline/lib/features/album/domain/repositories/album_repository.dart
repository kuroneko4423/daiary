import '../entities/album.dart';
import '../../../camera/domain/entities/photo.dart';

abstract class AlbumRepository {
  Future<List<Album>> getAlbums();
  Future<Album> getAlbum(String id);
  Future<Album> createAlbum({required String name, String? coverPhotoId});
  Future<Album> updateAlbum(String id, {String? name, String? coverPhotoId});
  Future<void> deleteAlbum(String id);
  Future<List<Photo>> getAlbumPhotos(String albumId);
  Future<void> addPhotosToAlbum(String albumId, List<String> photoIds);
  Future<void> removePhotoFromAlbum(String albumId, String photoId);
}

import '../models/photo.dart';

abstract class PhotoRepository {
  Future<List<Photo>> getPhotos({bool? favoritesOnly, bool? trashOnly});
  Future<Photo?> getPhoto(String id);
  Future<Photo> savePhoto(String sourcePath);
  Future<void> updatePhoto(String id, Map<String, dynamic> data);
  Future<void> deletePhoto(String id);
  Future<void> toggleFavorite(String id);
}

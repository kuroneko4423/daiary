import 'package:uuid/uuid.dart';
import '../../../camera/domain/entities/photo.dart';
import '../../domain/entities/album.dart';
import '../../domain/repositories/album_repository.dart';
import '../datasources/album_local_datasource.dart';

class AlbumRepositoryImpl implements AlbumRepository {
  final AlbumLocalDataSource _dataSource;
  final _uuid = const Uuid();

  AlbumRepositoryImpl(this._dataSource);

  @override
  Future<List<Album>> getAlbums() async {
    final data = await _dataSource.getAlbums();
    return data.map((e) => Album.fromMap(e)).toList();
  }

  @override
  Future<Album> getAlbum(String id) async {
    final data = await _dataSource.getAlbum(id);
    if (data == null) throw Exception('Album not found: $id');
    return Album.fromMap(data);
  }

  @override
  Future<Album> createAlbum({required String name, String? coverPhotoId}) async {
    final now = DateTime.now().toIso8601String();
    final album = {
      'id': _uuid.v4(),
      'name': name,
      'cover_photo_id': coverPhotoId,
      'created_at': now,
      'updated_at': now,
    };
    await _dataSource.insertAlbum(album);
    return Album.fromMap(album);
  }

  @override
  Future<Album> updateAlbum(String id, {String? name, String? coverPhotoId}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (coverPhotoId != null) updates['cover_photo_id'] = coverPhotoId;
    await _dataSource.updateAlbum(id, updates);
    return await getAlbum(id);
  }

  @override
  Future<void> deleteAlbum(String id) => _dataSource.deleteAlbum(id);

  @override
  Future<List<Photo>> getAlbumPhotos(String albumId) async {
    final data = await _dataSource.getAlbumPhotos(albumId);
    return data.map((e) => Photo.fromMap(e)).toList();
  }

  @override
  Future<void> addPhotosToAlbum(String albumId, List<String> photoIds) =>
      _dataSource.addPhotosToAlbum(albumId, photoIds);

  @override
  Future<void> removePhotoFromAlbum(String albumId, String photoId) =>
      _dataSource.removePhotoFromAlbum(albumId, photoId);
}

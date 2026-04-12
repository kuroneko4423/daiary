import 'package:daiary_shared/domain/models/album.dart';
import 'package:daiary_shared/domain/models/photo.dart';
import 'package:daiary_shared/domain/interfaces/album_repository.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/adapters/photo_adapter.dart';
import '../../../../data/adapters/album_adapter.dart';
import '../datasources/album_local_datasource.dart';

class AlbumRepositoryImpl implements AlbumRepository {
  final AlbumLocalDataSource _dataSource;
  final _uuid = const Uuid();

  AlbumRepositoryImpl(this._dataSource);

  @override
  Future<List<Album>> getAlbums() async {
    final data = await _dataSource.getAlbums();
    return data.map((e) => albumFromMap(e)).toList();
  }

  @override
  Future<Album> getAlbum(String id) async {
    final data = await _dataSource.getAlbum(id);
    if (data == null) throw Exception('Album not found: $id');
    return albumFromMap(data);
  }

  @override
  Future<Album> createAlbum(
      {required String name, String? coverPhotoId}) async {
    final now = DateTime.now().toIso8601String();
    final album = {
      'id': _uuid.v4(),
      'name': name,
      'cover_photo_id': coverPhotoId,
      'created_at': now,
      'updated_at': now,
    };
    await _dataSource.insertAlbum(album);
    return albumFromMap(album);
  }

  @override
  Future<Album> updateAlbum(String id,
      {String? name, String? coverPhotoId}) async {
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
    return data.map((e) => photoFromMap(e)).toList();
  }

  @override
  Future<void> addPhotosToAlbum(String albumId, List<String> photoIds) =>
      _dataSource.addPhotosToAlbum(albumId, photoIds);

  @override
  Future<void> removePhotoFromAlbum(String albumId, String photoId) =>
      _dataSource.removePhotoFromAlbum(albumId, photoId);
}

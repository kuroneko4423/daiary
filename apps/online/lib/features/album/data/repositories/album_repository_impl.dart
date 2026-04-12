import 'package:daiary_shared/domain/models/album.dart';
import 'package:daiary_shared/domain/models/photo.dart';
import 'package:daiary_shared/domain/interfaces/album_repository.dart';
import '../datasources/album_remote_datasource.dart';
import '../models/album_model.dart';

class AlbumRepositoryImpl implements AlbumRepository {
  final AlbumRemoteDataSource _dataSource;

  AlbumRepositoryImpl(this._dataSource);

  @override
  Future<List<Album>> getAlbums() async {
    final data = await _dataSource.getAlbums();
    return data.map((e) => AlbumModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Album> getAlbum(String id) async {
    final data = await _dataSource.getAlbum(id);
    return AlbumModel.fromJson(data);
  }

  @override
  Future<Album> createAlbum({required String name, String? coverPhotoId}) async {
    final data = await _dataSource.createAlbum({
      'name': name,
      if (coverPhotoId != null) 'cover_photo_id': coverPhotoId,
    });
    return AlbumModel.fromJson(data);
  }

  @override
  Future<Album> updateAlbum(String id, {String? name, String? coverPhotoId}) async {
    final data = await _dataSource.updateAlbum(id, {
      if (name != null) 'name': name,
      if (coverPhotoId != null) 'cover_photo_id': coverPhotoId,
    });
    return AlbumModel.fromJson(data);
  }

  @override
  Future<void> deleteAlbum(String id) => _dataSource.deleteAlbum(id);

  @override
  Future<List<Photo>> getAlbumPhotos(String albumId) async {
    // TODO: implement via data source
    return [];
  }

  @override
  Future<void> addPhotosToAlbum(String albumId, List<String> photoIds) =>
      _dataSource.addPhotos(albumId, photoIds);

  @override
  Future<void> removePhotoFromAlbum(String albumId, String photoId) =>
      _dataSource.removePhoto(albumId, photoId);
}

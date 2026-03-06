import '../../../../services/api_client.dart';

class AlbumRemoteDataSource {
  final ApiClient _apiClient;

  AlbumRemoteDataSource(this._apiClient);

  Future<List<dynamic>> getAlbums() async {
    final response = await _apiClient.get('/albums');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAlbum(String id) async {
    final response = await _apiClient.get('/albums/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAlbum(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/albums', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAlbum(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/albums/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAlbum(String id) async {
    await _apiClient.delete('/albums/$id');
  }

  Future<void> addPhotos(String albumId, List<String> photoIds) async {
    await _apiClient.post('/albums/$albumId/photos', data: {'photo_ids': photoIds});
  }

  Future<void> removePhoto(String albumId, String photoId) async {
    await _apiClient.delete('/albums/$albumId/photos/$photoId');
  }
}

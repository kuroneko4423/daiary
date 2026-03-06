import '../../../../services/api_client.dart';

class AiRemoteDataSource {
  final ApiClient _apiClient;

  AiRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> generateHashtags({
    required String photoId,
    required String language,
    required int count,
    required String usage,
  }) async {
    final response = await _apiClient.post('/ai/hashtags', data: {
      'photo_id': photoId,
      'language': language,
      'count': count,
      'usage': usage,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateCaption({
    required String photoId,
    required String language,
    required String style,
    required String length,
    String? customPrompt,
  }) async {
    final response = await _apiClient.post('/ai/caption', data: {
      'photo_id': photoId,
      'language': language,
      'style': style,
      'length': length,
      'custom_prompt': customPrompt,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUsage() async {
    final response = await _apiClient.get('/ai/usage');
    return response.data as Map<String, dynamic>;
  }
}

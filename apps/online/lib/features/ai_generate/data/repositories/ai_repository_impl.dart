import 'package:daiary_shared/domain/models/generation_result.dart';
import 'package:daiary_shared/domain/models/hashtag_result.dart';
import 'package:daiary_shared/domain/models/caption_result.dart';
import '../datasources/ai_remote_datasource.dart';

class AiRepositoryImpl {
  final AiRemoteDataSource _dataSource;

  AiRepositoryImpl(this._dataSource);

  Future<HashtagResult> generateHashtags({
    required String photoId,
    required String language,
    required int count,
    required String usage,
  }) async {
    final data = await _dataSource.generateHashtags(
      photoId: photoId,
      language: language,
      count: count,
      usage: usage,
    );
    return HashtagResultModel.fromJson(data);
  }

  Future<CaptionResult> generateCaption({
    required String photoId,
    required String language,
    required GenerationStyle style,
    required GenerationLength length,
    String? customPrompt,
  }) async {
    final data = await _dataSource.generateCaption(
      photoId: photoId,
      language: language,
      style: style.name,
      length: length.name,
      customPrompt: customPrompt,
    );
    return CaptionResultModel.fromJson(data);
  }

  Future<int> getRemainingUsage() async {
    final data = await _dataSource.getUsage();
    return data['remaining'] as int;
  }
}

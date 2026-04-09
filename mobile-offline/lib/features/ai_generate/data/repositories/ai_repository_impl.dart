import '../../domain/entities/generation_result.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_local_datasource.dart';
import '../models/hashtag_result.dart';
import '../models/caption_result.dart';

class AiRepositoryImpl implements AiRepository {
  final AiLocalDataSource _dataSource;

  AiRepositoryImpl(this._dataSource);

  @override
  Future<HashtagResult> generateHashtags({
    required String photoLocalPath,
    required String language,
    required int count,
    required String usage,
  }) async {
    final data = await _dataSource.generateHashtags(
      photoLocalPath: photoLocalPath,
      language: language,
      count: count,
      usage: usage,
    );
    return HashtagResultModel.fromJson(data);
  }

  @override
  Future<CaptionResult> generateCaption({
    required String photoLocalPath,
    required String language,
    required GenerationStyle style,
    required GenerationLength length,
    String? customPrompt,
  }) async {
    final data = await _dataSource.generateCaption(
      photoLocalPath: photoLocalPath,
      language: language,
      style: style.name,
      length: length.name,
      customPrompt: customPrompt,
    );
    return CaptionResultModel.fromJson(data);
  }

  @override
  Future<bool> isModelReady() => _dataSource.isModelReady();
}

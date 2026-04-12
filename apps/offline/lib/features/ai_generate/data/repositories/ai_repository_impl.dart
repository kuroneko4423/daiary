import 'package:daiary_shared/domain/models/generation_result.dart';
import 'package:daiary_shared/domain/models/hashtag_result.dart';
import 'package:daiary_shared/domain/models/caption_result.dart';
import 'package:daiary_shared/domain/interfaces/ai_service.dart';
import '../datasources/ai_local_datasource.dart';

class AiRepositoryImpl implements AiService {
  final AiLocalDataSource _dataSource;

  AiRepositoryImpl(this._dataSource);

  @override
  Future<HashtagResult> generateHashtags({
    required ImageInput image,
    required String language,
    required int count,
    required String usage,
  }) async {
    final localImage = image as LocalImageInput;
    final data = await _dataSource.generateHashtags(
      photoLocalPath: localImage.filePath,
      language: language,
      count: count,
      usage: usage,
    );
    return HashtagResultModel.fromJson(data);
  }

  @override
  Future<CaptionResult> generateCaption({
    required ImageInput image,
    required String language,
    required GenerationStyle style,
    required GenerationLength length,
    String? customPrompt,
  }) async {
    final localImage = image as LocalImageInput;
    final data = await _dataSource.generateCaption(
      photoLocalPath: localImage.filePath,
      language: language,
      style: style.name,
      length: length.name,
      customPrompt: customPrompt,
    );
    return CaptionResultModel.fromJson(data);
  }

  @override
  Future<bool> get isAvailable => _dataSource.isModelReady();
}

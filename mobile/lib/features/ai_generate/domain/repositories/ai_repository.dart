import '../entities/generation_result.dart';

abstract class AiRepository {
  Future<HashtagResult> generateHashtags({
    required String photoId,
    required String language,
    required int count,
    required String usage,
  });

  Future<CaptionResult> generateCaption({
    required String photoId,
    required String language,
    required GenerationStyle style,
    required GenerationLength length,
    String? customPrompt,
  });

  Future<int> getRemainingUsage();
}

import '../../domain/entities/generation_result.dart';

class HashtagResultModel extends HashtagResult {
  const HashtagResultModel({required super.hashtags});

  factory HashtagResultModel.fromJson(Map<String, dynamic> json) {
    return HashtagResultModel(
      hashtags: (json['hashtags'] as List<dynamic>).cast<String>(),
    );
  }
}

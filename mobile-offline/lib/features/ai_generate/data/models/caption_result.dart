import '../../domain/entities/generation_result.dart';

class CaptionResultModel extends CaptionResult {
  const CaptionResultModel({required super.caption});

  factory CaptionResultModel.fromJson(Map<String, dynamic> json) {
    return CaptionResultModel(
      caption: json['caption'] as String,
    );
  }
}

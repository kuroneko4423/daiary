import 'dart:typed_data';
import '../models/generation_result.dart';

/// Image input abstraction — absorbs the difference between
/// remote photo ID and local file path.
sealed class ImageInput {
  const ImageInput();
}

class RemoteImageInput extends ImageInput {
  final String photoId;
  const RemoteImageInput(this.photoId);
}

class LocalImageInput extends ImageInput {
  final String filePath;
  const LocalImageInput(this.filePath);
}

class BytesImageInput extends ImageInput {
  final Uint8List bytes;
  const BytesImageInput(this.bytes);
}

/// Unified AI service interface for online/offline.
abstract class AiService {
  Future<HashtagResult> generateHashtags({
    required ImageInput image,
    required String language,
    required int count,
    required String usage,
  });

  Future<CaptionResult> generateCaption({
    required ImageInput image,
    required String language,
    required GenerationStyle style,
    required GenerationLength length,
    String? customPrompt,
  });

  /// Check if the service is available.
  /// Online: always true (if network available).
  /// Offline: true if model is downloaded.
  Future<bool> get isAvailable;
}

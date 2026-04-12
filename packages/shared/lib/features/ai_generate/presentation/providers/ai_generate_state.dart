import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/generation_result.dart';
import '../../../../domain/interfaces/ai_service.dart';

final selectedStyleProvider =
    StateProvider<GenerationStyle>((ref) => GenerationStyle.casual);
final selectedLanguageProvider = StateProvider<String>((ref) => 'ja');
final selectedLengthProvider =
    StateProvider<GenerationLength>((ref) => GenerationLength.medium);
final customPromptProvider = StateProvider<String>((ref) => '');

class AiGenerateState {
  final List<String>? hashtags;
  final String? caption;
  final bool isLoadingHashtags;
  final bool isLoadingCaption;
  final String? error;
  final int? remainingGenerations;
  final bool? isModelReady;

  const AiGenerateState({
    this.hashtags,
    this.caption,
    this.isLoadingHashtags = false,
    this.isLoadingCaption = false,
    this.error,
    this.remainingGenerations,
    this.isModelReady,
  });

  AiGenerateState copyWith({
    List<String>? hashtags,
    String? caption,
    bool? isLoadingHashtags,
    bool? isLoadingCaption,
    String? error,
    int? remainingGenerations,
    bool? isModelReady,
  }) {
    return AiGenerateState(
      hashtags: hashtags ?? this.hashtags,
      caption: caption ?? this.caption,
      isLoadingHashtags: isLoadingHashtags ?? this.isLoadingHashtags,
      isLoadingCaption: isLoadingCaption ?? this.isLoadingCaption,
      error: error,
      remainingGenerations:
          remainingGenerations ?? this.remainingGenerations,
      isModelReady: isModelReady ?? this.isModelReady,
    );
  }
}

class AiGenerateNotifier extends StateNotifier<AiGenerateState> {
  final AiService _service;

  AiGenerateNotifier(this._service) : super(const AiGenerateState());

  Future<void> checkAvailability() async {
    final available = await _service.isAvailable;
    state = state.copyWith(isModelReady: available);
  }

  Future<void> generateHashtags({
    required ImageInput image,
    required String language,
    int count = 10,
    String usage = 'instagram',
  }) async {
    state = state.copyWith(isLoadingHashtags: true, error: null);
    try {
      final result = await _service.generateHashtags(
        image: image,
        language: language,
        count: count,
        usage: usage,
      );
      state = state.copyWith(
        hashtags: result.hashtags,
        isLoadingHashtags: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHashtags: false,
        error: e.toString(),
      );
    }
  }

  Future<void> generateCaption({
    required ImageInput image,
    required String language,
    required GenerationStyle style,
    required GenerationLength length,
    String? customPrompt,
  }) async {
    state = state.copyWith(isLoadingCaption: true, error: null);
    try {
      final result = await _service.generateCaption(
        image: image,
        language: language,
        style: style,
        length: length,
        customPrompt: customPrompt,
      );
      state = state.copyWith(
        caption: result.caption,
        isLoadingCaption: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCaption: false,
        error: e.toString(),
      );
    }
  }

  void clearResults() {
    state = const AiGenerateState();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ai_local_datasource.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/generation_result.dart';
import '../../domain/repositories/ai_repository.dart';

final selectedStyleProvider =
    StateProvider<GenerationStyle>((ref) => GenerationStyle.casual);
final selectedLanguageProvider = StateProvider<String>((ref) => 'ja');
final selectedLengthProvider =
    StateProvider<GenerationLength>((ref) => GenerationLength.medium);
final customPromptProvider = StateProvider<String>((ref) => '');

final aiLocalDataSourceProvider =
    Provider<AiLocalDataSource>((ref) => AiLocalDataSource());

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(ref.watch(aiLocalDataSourceProvider));
});

class AiGenerateState {
  final List<String>? hashtags;
  final String? caption;
  final bool isLoadingHashtags;
  final bool isLoadingCaption;
  final String? error;
  final bool isModelReady;

  const AiGenerateState({
    this.hashtags,
    this.caption,
    this.isLoadingHashtags = false,
    this.isLoadingCaption = false,
    this.error,
    this.isModelReady = false,
  });

  AiGenerateState copyWith({
    List<String>? hashtags,
    String? caption,
    bool? isLoadingHashtags,
    bool? isLoadingCaption,
    String? error,
    bool? isModelReady,
  }) {
    return AiGenerateState(
      hashtags: hashtags ?? this.hashtags,
      caption: caption ?? this.caption,
      isLoadingHashtags: isLoadingHashtags ?? this.isLoadingHashtags,
      isLoadingCaption: isLoadingCaption ?? this.isLoadingCaption,
      error: error,
      isModelReady: isModelReady ?? this.isModelReady,
    );
  }
}

class AiGenerateNotifier extends StateNotifier<AiGenerateState> {
  final AiRepository _repository;

  AiGenerateNotifier(this._repository) : super(const AiGenerateState());

  Future<void> checkModelReady() async {
    final ready = await _repository.isModelReady();
    state = state.copyWith(isModelReady: ready);
  }

  Future<void> generateHashtags({
    required String photoLocalPath,
    required String language,
    int count = 10,
    String usage = 'instagram',
  }) async {
    state = state.copyWith(isLoadingHashtags: true, error: null);
    try {
      final result = await _repository.generateHashtags(
        photoLocalPath: photoLocalPath,
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
    required String photoLocalPath,
    required String language,
    required GenerationStyle style,
    required GenerationLength length,
    String? customPrompt,
  }) async {
    state = state.copyWith(isLoadingCaption: true, error: null);
    try {
      final result = await _repository.generateCaption(
        photoLocalPath: photoLocalPath,
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

final aiGenerateNotifierProvider =
    StateNotifierProvider<AiGenerateNotifier, AiGenerateState>((ref) {
  return AiGenerateNotifier(ref.watch(aiRepositoryProvider));
});

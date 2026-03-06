import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_client.dart';
import '../../data/datasources/ai_remote_datasource.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/generation_result.dart';
import '../../domain/repositories/ai_repository.dart';

final selectedStyleProvider =
    StateProvider<GenerationStyle>((ref) => GenerationStyle.casual);
final selectedLanguageProvider = StateProvider<String>((ref) => 'ja');
final selectedLengthProvider =
    StateProvider<GenerationLength>((ref) => GenerationLength.medium);
final customPromptProvider = StateProvider<String>((ref) => '');

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  return AiRemoteDataSource(ref.watch(apiClientProvider));
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(ref.watch(aiRemoteDataSourceProvider));
});

class AiGenerateState {
  final List<String>? hashtags;
  final String? caption;
  final bool isLoadingHashtags;
  final bool isLoadingCaption;
  final String? error;
  final int remainingGenerations;

  const AiGenerateState({
    this.hashtags,
    this.caption,
    this.isLoadingHashtags = false,
    this.isLoadingCaption = false,
    this.error,
    this.remainingGenerations = 10,
  });

  AiGenerateState copyWith({
    List<String>? hashtags,
    String? caption,
    bool? isLoadingHashtags,
    bool? isLoadingCaption,
    String? error,
    int? remainingGenerations,
  }) {
    return AiGenerateState(
      hashtags: hashtags ?? this.hashtags,
      caption: caption ?? this.caption,
      isLoadingHashtags: isLoadingHashtags ?? this.isLoadingHashtags,
      isLoadingCaption: isLoadingCaption ?? this.isLoadingCaption,
      error: error,
      remainingGenerations:
          remainingGenerations ?? this.remainingGenerations,
    );
  }
}

class AiGenerateNotifier extends StateNotifier<AiGenerateState> {
  final AiRepository _repository;

  AiGenerateNotifier(this._repository) : super(const AiGenerateState());

  Future<void> generateHashtags({
    required String photoId,
    required String language,
    int count = 10,
    String usage = 'instagram',
  }) async {
    state = state.copyWith(isLoadingHashtags: true, error: null);
    try {
      final result = await _repository.generateHashtags(
        photoId: photoId,
        language: language,
        count: count,
        usage: usage,
      );
      state = state.copyWith(
        hashtags: result.hashtags,
        isLoadingHashtags: false,
        remainingGenerations: state.remainingGenerations - 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHashtags: false,
        error: e.toString(),
      );
    }
  }

  Future<void> generateCaption({
    required String photoId,
    required String language,
    required GenerationStyle style,
    required GenerationLength length,
    String? customPrompt,
  }) async {
    state = state.copyWith(isLoadingCaption: true, error: null);
    try {
      final result = await _repository.generateCaption(
        photoId: photoId,
        language: language,
        style: style,
        length: length,
        customPrompt: customPrompt,
      );
      state = state.copyWith(
        caption: result.caption,
        isLoadingCaption: false,
        remainingGenerations: state.remainingGenerations - 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCaption: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchUsage() async {
    try {
      final remaining = await _repository.getRemainingUsage();
      state = state.copyWith(remainingGenerations: remaining);
    } catch (_) {
      // Keep current value on error
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

import 'package:flutter_test/flutter_test.dart';
import 'package:daiary/features/ai_generate/presentation/providers/ai_generate_provider.dart';

void main() {
  group('AiGenerateState', () {
    test('initial values are correct', () {
      const state = AiGenerateState();

      expect(state.hashtags, isNull);
      expect(state.caption, isNull);
      expect(state.isLoadingHashtags, isFalse);
      expect(state.isLoadingCaption, isFalse);
      expect(state.error, isNull);
      expect(state.remainingGenerations, 10);
    });

    test('remainingGenerations defaults to 10', () {
      const state = AiGenerateState();
      expect(state.remainingGenerations, 10);
    });

    test('copyWith updates hashtags', () {
      const state = AiGenerateState();
      final updated = state.copyWith(hashtags: ['#photo', '#nature']);

      expect(updated.hashtags, ['#photo', '#nature']);
      expect(updated.caption, isNull);
      expect(updated.isLoadingHashtags, isFalse);
      expect(updated.isLoadingCaption, isFalse);
      expect(updated.error, isNull);
      expect(updated.remainingGenerations, 10);
    });

    test('copyWith updates caption', () {
      const state = AiGenerateState();
      final updated = state.copyWith(caption: 'A beautiful sunset');

      expect(updated.caption, 'A beautiful sunset');
      expect(updated.hashtags, isNull);
      expect(updated.isLoadingHashtags, isFalse);
      expect(updated.isLoadingCaption, isFalse);
      expect(updated.error, isNull);
    });

    test('copyWith updates error', () {
      const state = AiGenerateState();
      final updated = state.copyWith(error: 'Something went wrong');

      expect(updated.error, 'Something went wrong');
      expect(updated.hashtags, isNull);
      expect(updated.caption, isNull);
    });

    test('copyWith clears error when set to null', () {
      final state = const AiGenerateState().copyWith(error: 'an error');
      expect(state.error, 'an error');

      // copyWith passes error directly (not via ?? this.error),
      // so calling copyWith without error sets it to null
      final cleared = state.copyWith();
      expect(cleared.error, isNull);
    });

    test('copyWith updates isLoadingHashtags', () {
      const state = AiGenerateState();
      final updated = state.copyWith(isLoadingHashtags: true);

      expect(updated.isLoadingHashtags, isTrue);
      expect(updated.isLoadingCaption, isFalse);
    });

    test('copyWith updates isLoadingCaption', () {
      const state = AiGenerateState();
      final updated = state.copyWith(isLoadingCaption: true);

      expect(updated.isLoadingCaption, isTrue);
      expect(updated.isLoadingHashtags, isFalse);
    });

    test('copyWith updates remainingGenerations', () {
      const state = AiGenerateState();
      final updated = state.copyWith(remainingGenerations: 5);

      expect(updated.remainingGenerations, 5);
    });

    test('copyWith preserves existing values when not specified', () {
      final state = const AiGenerateState().copyWith(
        hashtags: ['#test'],
        caption: 'test caption',
        isLoadingHashtags: true,
        isLoadingCaption: true,
        remainingGenerations: 7,
      );

      final updated = state.copyWith(remainingGenerations: 6);

      expect(updated.hashtags, ['#test']);
      expect(updated.caption, 'test caption');
      expect(updated.isLoadingHashtags, isTrue);
      expect(updated.isLoadingCaption, isTrue);
      expect(updated.remainingGenerations, 6);
    });

    test('can be constructed with custom values', () {
      const state = AiGenerateState(
        hashtags: ['#ai', '#photo'],
        caption: 'AI generated caption',
        isLoadingHashtags: true,
        isLoadingCaption: false,
        error: 'test error',
        remainingGenerations: 3,
      );

      expect(state.hashtags, ['#ai', '#photo']);
      expect(state.caption, 'AI generated caption');
      expect(state.isLoadingHashtags, isTrue);
      expect(state.isLoadingCaption, isFalse);
      expect(state.error, 'test error');
      expect(state.remainingGenerations, 3);
    });
  });
}

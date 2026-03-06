import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photographer/features/ai_generate/domain/entities/generation_result.dart';

void main() {
  group('GenerationStyle', () {
    test('has all expected values', () {
      expect(GenerationStyle.values.length, 6);
      expect(
        GenerationStyle.values,
        containsAll([
          GenerationStyle.poem,
          GenerationStyle.business,
          GenerationStyle.casual,
          GenerationStyle.news,
          GenerationStyle.humor,
          GenerationStyle.custom,
        ]),
      );
    });

    test('poem has correct label', () {
      expect(GenerationStyle.poem.label, 'ポエム風');
    });

    test('business has correct label', () {
      expect(GenerationStyle.business.label, 'ビジネス風');
    });

    test('casual has correct label', () {
      expect(GenerationStyle.casual.label, 'カジュアル風');
    });

    test('news has correct label', () {
      expect(GenerationStyle.news.label, 'ニュース風');
    });

    test('humor has correct label', () {
      expect(GenerationStyle.humor.label, 'ユーモア風');
    });

    test('custom has correct label', () {
      expect(GenerationStyle.custom.label, 'カスタム');
    });
  });

  group('GenerationLength', () {
    test('has all expected values', () {
      expect(GenerationLength.values.length, 3);
      expect(
        GenerationLength.values,
        containsAll([
          GenerationLength.short_,
          GenerationLength.medium,
          GenerationLength.long_,
        ]),
      );
    });

    test('short_ has correct label', () {
      expect(GenerationLength.short_.label, '短文');
    });

    test('medium has correct label', () {
      expect(GenerationLength.medium.label, '中文');
    });

    test('long_ has correct label', () {
      expect(GenerationLength.long_.label, '長文');
    });
  });

  group('HashtagResult', () {
    test('can be created with a list of hashtags', () {
      const result = HashtagResult(hashtags: ['#photo', '#nature', '#sunset']);

      expect(result.hashtags, ['#photo', '#nature', '#sunset']);
    });

    test('asText joins hashtags with spaces', () {
      const result = HashtagResult(hashtags: ['#photo', '#nature', '#sunset']);

      expect(result.asText, '#photo #nature #sunset');
    });

    test('asText returns empty string for empty list', () {
      const result = HashtagResult(hashtags: []);

      expect(result.asText, '');
    });

    test('asText works with single hashtag', () {
      const result = HashtagResult(hashtags: ['#solo']);

      expect(result.asText, '#solo');
    });
  });

  group('CaptionResult', () {
    test('can be created with a caption', () {
      const result = CaptionResult(caption: 'A beautiful sunset over the ocean');

      expect(result.caption, 'A beautiful sunset over the ocean');
    });

    test('can be created with empty caption', () {
      const result = CaptionResult(caption: '');

      expect(result.caption, '');
    });
  });
}

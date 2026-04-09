class HashtagResult {
  final List<String> hashtags;

  const HashtagResult({required this.hashtags});

  String get asText => hashtags.join(' ');
}

class CaptionResult {
  final String caption;

  const CaptionResult({required this.caption});
}

enum GenerationStyle {
  poem('ポエム風'),
  business('ビジネス風'),
  casual('カジュアル風'),
  news('ニュース風'),
  humor('ユーモア風'),
  custom('カスタム');

  final String label;
  const GenerationStyle(this.label);
}

enum GenerationLength {
  short_('短文'),
  medium('中文'),
  long_('長文');

  final String label;
  const GenerationLength(this.label);
}

class ShareTemplates {
  ShareTemplates._();

  static const String appName = 'dAIary';
  static const String defaultHashtag = '#dAIary';
  static const String defaultShareText =
      'dAIaryで作成！\n#dAIary';

  /// Build share text combining generated content with default template.
  static String buildShareText({String? hashtags, String? caption}) {
    final parts = <String>[];
    if (caption != null && caption.isNotEmpty) {
      parts.add(caption);
    }
    if (hashtags != null && hashtags.isNotEmpty) {
      parts.add(hashtags);
    }
    parts.add(defaultShareText);
    return parts.join('\n\n');
  }
}

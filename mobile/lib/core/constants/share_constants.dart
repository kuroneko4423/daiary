class ShareTemplates {
  ShareTemplates._();

  static const String appName = 'AI Photographer';
  static const String defaultHashtag = '#AIPhotographer';
  static const String defaultShareText =
      'AIフォトグラファーで作成！\n#AIPhotographer';

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

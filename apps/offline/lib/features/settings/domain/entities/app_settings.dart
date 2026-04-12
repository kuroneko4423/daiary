class AppSettings {
  final String defaultLanguage;
  final String defaultStyle;
  final String themeMode;
  final bool notificationsEnabled;

  const AppSettings({
    this.defaultLanguage = 'ja',
    this.defaultStyle = 'casual',
    this.themeMode = 'system',
    this.notificationsEnabled = true,
  });
}

class AppSettings {
  final String defaultLanguage;
  final String defaultStyle;
  final bool notificationsEnabled;

  const AppSettings({
    this.defaultLanguage = 'ja',
    this.defaultStyle = 'casual',
    this.notificationsEnabled = true,
  });
}

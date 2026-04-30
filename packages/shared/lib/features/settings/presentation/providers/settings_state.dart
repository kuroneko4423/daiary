import 'package:flutter_riverpod/flutter_riverpod.dart';

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

abstract class SettingsNotifierBase extends StateNotifier<AppSettings> {
  SettingsNotifierBase() : super(const AppSettings());

  Future<void> loadSettings();

  Future<void> setDefaultLanguage(String language) async {
    state = AppSettings(
      defaultLanguage: language,
      defaultStyle: state.defaultStyle,
      notificationsEnabled: state.notificationsEnabled,
    );
    await saveSettings(state);
  }

  Future<void> setDefaultStyle(String style) async {
    state = AppSettings(
      defaultLanguage: state.defaultLanguage,
      defaultStyle: style,
      notificationsEnabled: state.notificationsEnabled,
    );
    await saveSettings(state);
  }

  Future<void> saveSettings(AppSettings settings);
}

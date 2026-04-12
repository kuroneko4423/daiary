import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

abstract class SettingsNotifierBase extends StateNotifier<AppSettings> {
  SettingsNotifierBase() : super(const AppSettings());

  Future<void> loadSettings();

  Future<void> setDefaultLanguage(String language) async {
    state = AppSettings(
      defaultLanguage: language,
      defaultStyle: state.defaultStyle,
      themeMode: state.themeMode,
      notificationsEnabled: state.notificationsEnabled,
    );
    await saveSettings(state);
  }

  Future<void> setDefaultStyle(String style) async {
    state = AppSettings(
      defaultLanguage: state.defaultLanguage,
      defaultStyle: style,
      themeMode: state.themeMode,
      notificationsEnabled: state.notificationsEnabled,
    );
    await saveSettings(state);
  }

  Future<void> setThemeMode(String mode) async {
    state = AppSettings(
      defaultLanguage: state.defaultLanguage,
      defaultStyle: state.defaultStyle,
      themeMode: mode,
      notificationsEnabled: state.notificationsEnabled,
    );
    await saveSettings(state);
  }

  ThemeMode get themeMode {
    switch (state.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveSettings(AppSettings settings);
}

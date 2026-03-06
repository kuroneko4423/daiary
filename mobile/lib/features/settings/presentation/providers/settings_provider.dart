import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_settings.dart';
import '../../data/repositories/settings_repository.dart';

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => SettingsRepository());

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _repository.getSettings();
    state = settings;
  }

  Future<void> setDefaultLanguage(String language) async {
    state = AppSettings(
      defaultLanguage: language,
      defaultStyle: state.defaultStyle,
      themeMode: state.themeMode,
      notificationsEnabled: state.notificationsEnabled,
    );
    await _repository.saveSettings(state);
  }

  Future<void> setDefaultStyle(String style) async {
    state = AppSettings(
      defaultLanguage: state.defaultLanguage,
      defaultStyle: style,
      themeMode: state.themeMode,
      notificationsEnabled: state.notificationsEnabled,
    );
    await _repository.saveSettings(state);
  }

  Future<void> setThemeMode(String mode) async {
    state = AppSettings(
      defaultLanguage: state.defaultLanguage,
      defaultStyle: state.defaultStyle,
      themeMode: mode,
      notificationsEnabled: state.notificationsEnabled,
    );
    await _repository.saveSettings(state);
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
}

import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings.dart';

class SettingsRepository {
  static const _keyLanguage = 'settings_default_language';
  static const _keyStyle = 'settings_default_style';
  static const _keyTheme = 'settings_theme_mode';
  static const _keyNotifications = 'settings_notifications';

  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      defaultLanguage: prefs.getString(_keyLanguage) ?? 'ja',
      defaultStyle: prefs.getString(_keyStyle) ?? 'casual',
      themeMode: prefs.getString(_keyTheme) ?? 'system',
      notificationsEnabled: prefs.getBool(_keyNotifications) ?? true,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, settings.defaultLanguage);
    await prefs.setString(_keyStyle, settings.defaultStyle);
    await prefs.setString(_keyTheme, settings.themeMode);
    await prefs.setBool(_keyNotifications, settings.notificationsEnabled);
  }
}

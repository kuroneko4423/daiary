import '../../domain/entities/app_settings.dart';

class SettingsRepository {
  Future<AppSettings> getSettings() async {
    // TODO: Load from SharedPreferences
    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    // TODO: Save to SharedPreferences
  }
}

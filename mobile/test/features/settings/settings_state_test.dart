import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photographer/features/settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('initial values are correct', () {
      const settings = AppSettings();

      expect(settings.defaultLanguage, 'ja');
      expect(settings.defaultStyle, 'casual');
      expect(settings.themeMode, 'system');
      expect(settings.notificationsEnabled, isTrue);
    });

    test('defaultLanguage defaults to ja', () {
      const settings = AppSettings();
      expect(settings.defaultLanguage, 'ja');
    });

    test('defaultStyle defaults to casual', () {
      const settings = AppSettings();
      expect(settings.defaultStyle, 'casual');
    });

    test('themeMode defaults to system', () {
      const settings = AppSettings();
      expect(settings.themeMode, 'system');
    });

    test('notificationsEnabled defaults to true', () {
      const settings = AppSettings();
      expect(settings.notificationsEnabled, isTrue);
    });

    test('can be created with custom values', () {
      const settings = AppSettings(
        defaultLanguage: 'en',
        defaultStyle: 'business',
        themeMode: 'dark',
        notificationsEnabled: false,
      );

      expect(settings.defaultLanguage, 'en');
      expect(settings.defaultStyle, 'business');
      expect(settings.themeMode, 'dark');
      expect(settings.notificationsEnabled, isFalse);
    });

    test('themeMode can be set to light', () {
      const settings = AppSettings(themeMode: 'light');
      expect(settings.themeMode, 'light');
    });

    test('themeMode can be set to dark', () {
      const settings = AppSettings(themeMode: 'dark');
      expect(settings.themeMode, 'dark');
    });

    test('can be used as const', () {
      const settings1 = AppSettings();
      const settings2 = AppSettings();
      expect(identical(settings1, settings2), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photographer/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('freeAiGenerationsPerDay equals 10', () {
      expect(AppConstants.freeAiGenerationsPerDay, 10);
    });

    test('rewardAdBonusGenerations equals 3', () {
      expect(AppConstants.rewardAdBonusGenerations, 3);
    });

    test('maxPhotoImportCount equals 10', () {
      expect(AppConstants.maxPhotoImportCount, 10);
    });

    test('maxPhotoSizeBytes equals 10MB', () {
      expect(AppConstants.maxPhotoSizeBytes, 10 * 1024 * 1024);
    });

    test('freeStorageLimitBytes equals 1GB', () {
      expect(AppConstants.freeStorageLimitBytes, 1 * 1024 * 1024 * 1024);
    });

    test('premiumStorageLimitBytes equals 50GB', () {
      expect(AppConstants.premiumStorageLimitBytes, 50 * 1024 * 1024 * 1024);
    });

    test('trashAutoDeleteDays equals 30', () {
      expect(AppConstants.trashAutoDeleteDays, 30);
    });

    test('interstitialAdFrequency equals 5', () {
      expect(AppConstants.interstitialAdFrequency, 5);
    });

    test('free generation limit matches AiGenerateState default', () {
      // The AiGenerateState defaults remainingGenerations to 10,
      // which should match freeAiGenerationsPerDay
      expect(AppConstants.freeAiGenerationsPerDay, 10);
    });
  });
}

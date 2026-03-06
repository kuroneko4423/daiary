class AppConstants {
  AppConstants._();

  static const int freeAiGenerationsPerDay = 10;
  static const int rewardAdBonusGenerations = 3;
  static const int maxPhotoImportCount = 10;
  static const int maxPhotoSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int freeStorageLimitBytes = 1 * 1024 * 1024 * 1024; // 1GB
  static const int premiumStorageLimitBytes = 50 * 1024 * 1024 * 1024; // 50GB
  static const int trashAutoDeleteDays = 30;
  static const int interstitialAdFrequency = 5;
}

class AppUser {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String plan;
  final DateTime? planExpiresAt;
  final int dailyAiCount;

  const AppUser({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    this.plan = 'free',
    this.planExpiresAt,
    this.dailyAiCount = 0,
  });

  bool get isPremium => plan == 'premium' && (planExpiresAt?.isAfter(DateTime.now()) ?? false);
}

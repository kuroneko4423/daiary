import '../../domain/entities/user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    super.avatarUrl,
    super.plan,
    super.planExpiresAt,
    super.dailyAiCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      plan: json['plan'] as String? ?? 'free',
      planExpiresAt: json['plan_expires_at'] != null
          ? DateTime.parse(json['plan_expires_at'] as String)
          : null,
      dailyAiCount: json['daily_ai_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'plan': plan,
      'plan_expires_at': planExpiresAt?.toIso8601String(),
      'daily_ai_count': dailyAiCount,
    };
  }
}

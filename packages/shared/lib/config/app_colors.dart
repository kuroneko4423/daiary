import 'package:flutter/material.dart';

/// デザインルール準拠のカラートークン
/// design-rules.md のダークモード仕様に準拠
class AppColors {
  AppColors._();

  // ============================================================
  // Brand Colors - Crimson (赤)
  // ============================================================
  static const Color crimson50 = Color(0xFFFDF2F4);
  static const Color crimson100 = Color(0xFFFAE0E4);
  static const Color crimson700 = Color(0xFFB8001F); // Primary (light)
  static const Color crimson800 = Color(0xFF8E0017);
  static const Color crimson900 = Color(0xFF6B0011);

  // Dark mode primary (明度を上げた赤)
  static const Color primary = Color(0xFFE63946);
  static const Color primaryLight = Color(0xFFFCA5A5);
  static const Color primaryDark = Color(0xFF3D0009);

  // ============================================================
  // Foundation Colors - Black (黒)
  // ============================================================
  static const Color black = Color(0xFF000000);
  static const Color ink950 = Color(0xFF0A0A0A); // 背景(基底)
  static const Color ink900 = Color(0xFF1A1A1A); // 背景(前面)
  static const Color ink800 = Color(0xFF262626); // ボーダー、サブ背景

  // ============================================================
  // Neutral Colors
  // ============================================================
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral200 = Color(0xFFE4E4E7);
  static const Color neutral300 = Color(0xFFD4D4D8);
  static const Color neutral400 = Color(0xFFA1A1AA);
  static const Color neutral500 = Color(0xFF71717A);
  static const Color neutral700 = Color(0xFF3F3F46);
  static const Color neutral900 = Color(0xFF18181B);

  // ============================================================
  // Semantic Colors (ダークモード調整済)
  // ============================================================
  static const Color success = Color(0xFF4ADE80);
  static const Color successBg = Color(0xFF0F2A18);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color info = Color(0xFF94A3B8);

  // ============================================================
  // 透明度ヘルパー
  // ============================================================
  static Color whiteAlpha(double opacity) =>
      Colors.white.withValues(alpha: opacity);
}

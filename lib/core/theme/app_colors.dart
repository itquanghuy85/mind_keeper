import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF6355E7);
  static const Color primaryDark = Color(0xFF4B3FD1);
  static const Color primarySoft = Color(0xFFEEEBFF);
  static const Color primarySoftAlt = Color(0xFFF3F1FF);

  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F2F7);

  static const Color textPrimary = Color(0xFF1B1D2A);
  static const Color textSecondary = Color(0xFF6B6F80);
  static const Color textTertiary = Color(0xFF9AA0B0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE7E9F0);
  static const Color borderStrong = Color(0xFFD6D9E4);

  static const Color success = Color(0xFF22B573);
  static const Color successSoft = Color(0xFFE4F7EE);
  static const Color warning = Color(0xFFF0A02A);
  static const Color warningSoft = Color(0xFFFDF1DF);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSoft = Color(0xFFFDEBEC);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFE8F1FE);

  static const Color ratingAgain = Color(0xFFE5484D);
  static const Color ratingAgainSoft = Color(0xFFFDEBEC);
  static const Color ratingHard = Color(0xFFF0A02A);
  static const Color ratingHardSoft = Color(0xFFFDF1DF);
  static const Color ratingGood = Color(0xFF3B82F6);
  static const Color ratingGoodSoft = Color(0xFFE8F1FE);
  static const Color ratingEasy = Color(0xFF22B573);
  static const Color ratingEasySoft = Color(0xFFE4F7EE);

  static const Color overlay = Color(0x66101223);

  static const List<Color> primaryGradient = <Color>[primary, Color(0xFF8B7CFF)];
}

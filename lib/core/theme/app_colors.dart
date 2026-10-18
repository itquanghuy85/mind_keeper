import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary - Modern Indigo
  static const Color primary = Color(0xFF5B5BD6);
  static const Color primaryDark = Color(0xFF4A4AC8);
  static const Color primaryPressed = Color(0xFF3D3DBA);
  static const Color primarySoft = Color(0xFFEDEBFF);
  static const Color primarySoftAlt = Color(0xFFF3F1FF);
  static const Color primaryContainer = Color(0xFFEDEBFF);
  static const Color onPrimaryContainer = Color(0xFF4A4AC8);

  // Secondary - Teal
  static const Color secondary = Color(0xFF168F83);
  static const Color secondaryDark = Color(0xFF0F736A);
  static const Color secondarySoft = Color(0xFFE0F5F3);

  // Tertiary - Info Blue
  static const Color tertiary = Color(0xFF2F6FED);
  static const Color tertiarySoft = Color(0xFFE7EFFE);

  // Background & Surface - Light
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFAFBFC);
  static const Color surfaceContainer = Color(0xFFF7F8FC);
  static const Color surfaceContainerHigh = Color(0xFFF0F2F8);
  static const Color surfaceContainerHighest = Color(0xFFE8ECF5);
  static const Color surfaceMuted = Color(0xFFEFF1F6);
  static const Color surfaceMutedStrong = Color(0xFFE7EAF2);

  // Background & Surface - Dark
  static const Color backgroundDark = Color(0xFF11131A);
  static const Color surfaceDark = Color(0xFF1B1F2A);
  static const Color surfaceContainerLowestDark = Color(0xFF161922);
  static const Color surfaceContainerLowDark = Color(0xFF1E2330);
  static const Color surfaceContainerDark = Color(0xFF252A3A);
  static const Color surfaceContainerHighDark = Color(0xFF2D3446);
  static const Color surfaceContainerHighestDark = Color(0xFF353D52);

  // Text - Light
  static const Color textPrimary = Color(0xFF171927);
  static const Color textSecondary = Color(0xFF4A5068);
  static const Color textTertiary = Color(0xFF6D758E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF171927);

  // Text - Dark
  static const Color textPrimaryDark = Color(0xFFF0F2F8);
  static const Color textSecondaryDark = Color(0xFFADB5C5);
  static const Color textTertiaryDark = Color(0xFF8A93A8);
  static const Color textOnPrimaryDark = Color(0xFFFFFFFF);

  // Border - Light
  static const Color border = Color(0xFFE3E7EF);
  static const Color borderStrong = Color(0xFFCED3E1);
  static const Color outline = Color(0xFFE3E7EF);
  static const Color outlineVariant = Color(0xFFCED3E1);

  // Border - Dark
  static const Color borderDark = Color(0xFF343949);
  static const Color borderStrongDark = Color(0xFF4A5068);
  static const Color outlineDark = Color(0xFF343949);
  static const Color outlineVariantDark = Color(0xFF4A5068);

  // Semantic Colors
  static const Color success = Color(0xFF1FA36B);
  static const Color successText = Color(0xFF157A50);
  static const Color successSoft = Color(0xFFE3F6ED);
  static const Color successContainer = Color(0xFFE3F6ED);
  static const Color onSuccessContainer = Color(0xFF157A50);

  static const Color warning = Color(0xFFE8930C);
  static const Color warningText = Color(0xFF9A6208);
  static const Color warningSoft = Color(0xFFFCF0DC);
  static const Color warningContainer = Color(0xFFFCF0DC);
  static const Color onWarningContainer = Color(0xFF9A6208);

  static const Color danger = Color(0xFFDC4437);
  static const Color dangerText = Color(0xFFB83A2E);
  static const Color dangerSoft = Color(0xFFFCEAE8);
  static const Color dangerContainer = Color(0xFFFCEAE8);
  static const Color onDangerContainer = Color(0xFFB83A2E);

  static const Color info = Color(0xFF2F6FED);
  static const Color infoText = Color(0xFF1E54C9);
  static const Color infoSoft = Color(0xFFE7EFFE);
  static const Color infoContainer = Color(0xFFE7EFFE);
  static const Color onInfoContainer = Color(0xFF1E54C9);

  // FSRS Rating Colors
  static const Color ratingAgain = danger;
  static const Color ratingAgainSoft = dangerSoft;
  static const Color ratingHard = warning;
  static const Color ratingHardSoft = warningSoft;
  static const Color ratingGood = info;
  static const Color ratingGoodSoft = infoSoft;
  static const Color ratingEasy = success;
  static const Color ratingEasySoft = successSoft;

  // Overlay & Shadow
  static const Color overlay = Color(0x66101223);
  static const Color overlayDark = Color(0x80000000);

  static const Color shadow = Color(0x1210182E);
  static const Color shadowStrong = Color(0x1F10182E);
  static const Color shadowDark = Color(0x33000000);

  // Selection
  static const Color selection = Color(0x3D6355E7);

  // Gradients
  static const List<Color> primaryGradient = <Color>[
    primary,
    Color(0xFF7A7AFF),
  ];
  static const List<Color> iconGradient = <Color>[
    Color(0xFF6E60F0),
    Color(0xFF4A3ED0),
  ];
  static const List<Color> surfaceGradient = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF7F8FC),
  ];
  static const List<Color> surfaceGradientDark = <Color>[
    Color(0xFF1B1F2A),
    Color(0xFF11131A),
  ];
}
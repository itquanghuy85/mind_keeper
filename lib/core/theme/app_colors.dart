import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary - Zalo Blue
  static const Color primary = Color(0xFF0068FF);
  static const Color primaryDark = Color(0xFF0059DF);
  static const Color primaryPressed = Color(0xFF004AB8);
  static const Color primarySoft = Color(0xFFEAF3FF);
  static const Color primarySoftAlt = Color(0xFFF1F7FF);
  static const Color primaryContainer = Color(0xFFEAF3FF);
  static const Color onPrimaryContainer = Color(0xFF0050CC);

  /// Xanh sáng cho điểm nhấn trên nền tối (đảm bảo tương phản).
  static const Color primaryBright = Color(0xFF4C9AFF);

  // Secondary - Teal
  static const Color secondary = Color(0xFF168F83);
  static const Color secondaryDark = Color(0xFF0F736A);
  static const Color secondarySoft = Color(0xFFE0F5F3);

  // Tertiary - Sky Blue
  static const Color tertiary = Color(0xFF0EA5E9);
  static const Color tertiarySoft = Color(0xFFE6F7FE);

  // Background & Surface - Light
  static const Color background = Color(0xFFF4F8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF9FBFF);
  static const Color surfaceContainer = Color(0xFFF4F8FF);
  static const Color surfaceContainerHigh = Color(0xFFEBF1FA);
  static const Color surfaceContainerHighest = Color(0xFFE1E9F5);
  static const Color surfaceMuted = Color(0xFFEDF2FA);
  static const Color surfaceMutedStrong = Color(0xFFE1E9F5);

  // Background & Surface - Dark
  static const Color backgroundDark = Color(0xFF101722);
  static const Color surfaceDark = Color(0xFF182334);
  static const Color surfaceContainerLowestDark = Color(0xFF131B28);
  static const Color surfaceContainerLowDark = Color(0xFF1B2637);
  static const Color surfaceContainerDark = Color(0xFF1E2B3E);
  static const Color surfaceContainerHighDark = Color(0xFF202F43);
  static const Color surfaceContainerHighestDark = Color(0xFF2A3B53);

  // Text - Light
  static const Color textPrimary = Color(0xFF172B4D);
  static const Color textSecondary = Color(0xFF536780);
  static const Color textTertiary = Color(0xFF617498);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF172B4D);

  // Text - Dark
  static const Color textPrimaryDark = Color(0xFFF2F6FC);
  static const Color textSecondaryDark = Color(0xFFB4C3D8);
  static const Color textTertiaryDark = Color(0xFF8497B0);
  static const Color textOnPrimaryDark = Color(0xFFFFFFFF);

  // Border - Light
  static const Color border = Color(0xFFDCE5F0);
  static const Color borderStrong = Color(0xFFC6D2E2);
  static const Color outline = Color(0xFFDCE5F0);
  static const Color outlineVariant = Color(0xFFC6D2E2);

  // Border - Dark
  static const Color borderDark = Color(0xFF35465D);
  static const Color borderStrongDark = Color(0xFF476181);
  static const Color outlineDark = Color(0xFF35465D);
  static const Color outlineVariantDark = Color(0xFF476181);

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

  // ===== Dark variants (dùng cho AppPalette / ThemeExtension) =====
  static const Color primarySoftDark = Color(0xFF14315C);
  static const Color primarySoftAltDark = Color(0xFF16345A);
  static const Color primaryContainerDark = Color(0xFF14315C);
  static const Color onPrimaryContainerDark = Color(0xFF8FBBFF);
  static const Color secondarySoftDark = Color(0xFF0F3A34);
  static const Color surfaceMutedDark = Color(0xFF1F2C40);
  static const Color surfaceMutedStrongDark = Color(0xFF26344A);
  static const Color textOnSurfaceDark = Color(0xFFF2F6FC);

  static const Color successTextDark = Color(0xFF66D6A3);
  static const Color successSoftDark = Color(0xFF10382C);
  static const Color successContainerDark = Color(0xFF10382C);
  static const Color onSuccessContainerDark = Color(0xFF66D6A3);

  static const Color warningTextDark = Color(0xFFF5B85C);
  static const Color warningSoftDark = Color(0xFF3A2B10);
  static const Color warningContainerDark = Color(0xFF3A2B10);
  static const Color onWarningContainerDark = Color(0xFFF5B85C);

  static const Color dangerTextDark = Color(0xFFFF9B93);
  static const Color dangerSoftDark = Color(0xFF3E1B1B);
  static const Color dangerContainerDark = Color(0xFF3E1B1B);
  static const Color onDangerContainerDark = Color(0xFFFF9B93);

  static const Color infoTextDark = Color(0xFF8FBBFF);
  static const Color infoSoftDark = Color(0xFF14305E);
  static const Color infoContainerDark = Color(0xFF14305E);
  static const Color onInfoContainerDark = Color(0xFF8FBBFF);

  // Overlay & Shadow
  static const Color overlay = Color(0x66101223);
  static const Color overlayDark = Color(0x80000000);

  static const Color shadow = Color(0x120A1B33);
  static const Color shadowStrong = Color(0x1F0A1B33);
  static const Color shadowDark = Color(0x33000000);

  // Selection
  static const Color selection = Color(0x3D0068FF);

  // Gradients
  static const List<Color> primaryGradient = <Color>[
    primary,
    Color(0xFF4C9AFF),
  ];
  static const List<Color> iconGradient = <Color>[
    Color(0xFF4C9AFF),
    Color(0xFF0068FF),
  ];
  static const List<Color> surfaceGradient = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF4F8FF),
  ];
  static const List<Color> surfaceGradientDark = <Color>[
    Color(0xFF182334),
    Color(0xFF101722),
  ];
}

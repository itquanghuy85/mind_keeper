import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Bảng màu theo theme (light/dark) — dùng cho card, chip, badge, text và
/// border thay cho [AppColors] static vốn chỉ có giá trị light.
///
/// Nguồn màu chính vẫn là `ColorScheme`; lớp này bổ sung các token mềm
/// (soft/container/text/border) chưa có trong `ColorScheme`.
/// Truy cập: `context.appColors` hoặc `AppPalette.of(context)`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryBright,
    required this.primaryPressed,
    required this.primarySoft,
    required this.primarySoftAlt,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceMuted,
    required this.surfaceMutedStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,
    required this.textOnSurface,
    required this.border,
    required this.borderStrong,
    required this.outline,
    required this.outlineVariant,
    required this.success,
    required this.successText,
    required this.successSoft,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningText,
    required this.warningSoft,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerText,
    required this.dangerSoft,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.info,
    required this.infoText,
    required this.infoSoft,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.ratingAgain,
    required this.ratingAgainSoft,
    required this.ratingHard,
    required this.ratingHardSoft,
    required this.ratingGood,
    required this.ratingGoodSoft,
    required this.ratingEasy,
    required this.ratingEasySoft,
  });

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? lightPalette;
  }

  /// Giá trị palette sáng (mặc định/light).
  static const AppPalette lightPalette = AppPalette(
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primaryBright: AppColors.primaryBright,
    primaryPressed: AppColors.primaryPressed,
    primarySoft: AppColors.primarySoft,
    primarySoftAlt: AppColors.primarySoftAlt,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    surfaceMuted: AppColors.surfaceMuted,
    surfaceMutedStrong: AppColors.surfaceMutedStrong,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textOnPrimary: AppColors.textOnPrimary,
    textOnSurface: AppColors.textOnSurface,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    success: AppColors.success,
    successText: AppColors.successText,
    successSoft: AppColors.successSoft,
    successContainer: AppColors.successContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    warning: AppColors.warning,
    warningText: AppColors.warningText,
    warningSoft: AppColors.warningSoft,
    warningContainer: AppColors.warningContainer,
    onWarningContainer: AppColors.onWarningContainer,
    danger: AppColors.danger,
    dangerText: AppColors.dangerText,
    dangerSoft: AppColors.dangerSoft,
    dangerContainer: AppColors.dangerContainer,
    onDangerContainer: AppColors.onDangerContainer,
    info: AppColors.info,
    infoText: AppColors.infoText,
    infoSoft: AppColors.infoSoft,
    infoContainer: AppColors.infoContainer,
    onInfoContainer: AppColors.onInfoContainer,
    ratingAgain: AppColors.ratingAgain,
    ratingAgainSoft: AppColors.ratingAgainSoft,
    ratingHard: AppColors.ratingHard,
    ratingHardSoft: AppColors.ratingHardSoft,
    ratingGood: AppColors.ratingGood,
    ratingGoodSoft: AppColors.ratingGoodSoft,
    ratingEasy: AppColors.ratingEasy,
    ratingEasySoft: AppColors.ratingEasySoft,
  );

  /// Giá trị palette tối (dark theme).
  static const AppPalette darkPalette = AppPalette(
    primary: AppColors.primaryBright,
    primaryDark: AppColors.primaryBright,
    primaryBright: AppColors.primaryBright,
    primaryPressed: AppColors.primaryPressed,
    primarySoft: AppColors.primarySoftDark,
    primarySoftAlt: AppColors.primarySoftAltDark,
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: AppColors.onPrimaryContainerDark,
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
    surfaceContainerLow: AppColors.surfaceContainerLowDark,
    surfaceContainer: AppColors.surfaceContainerDark,
    surfaceContainerHigh: AppColors.surfaceContainerHighDark,
    surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
    surfaceMuted: AppColors.surfaceMutedDark,
    surfaceMutedStrong: AppColors.surfaceMutedStrongDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textTertiary: AppColors.textTertiaryDark,
    textOnPrimary: AppColors.textOnPrimaryDark,
    textOnSurface: AppColors.textOnSurfaceDark,
    border: AppColors.borderDark,
    borderStrong: AppColors.borderStrongDark,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,
    success: AppColors.success,
    successText: AppColors.successTextDark,
    successSoft: AppColors.successSoftDark,
    successContainer: AppColors.successContainerDark,
    onSuccessContainer: AppColors.onSuccessContainerDark,
    warning: AppColors.warning,
    warningText: AppColors.warningTextDark,
    warningSoft: AppColors.warningSoftDark,
    warningContainer: AppColors.warningContainerDark,
    onWarningContainer: AppColors.onWarningContainerDark,
    danger: AppColors.danger,
    dangerText: AppColors.dangerTextDark,
    dangerSoft: AppColors.dangerSoftDark,
    dangerContainer: AppColors.dangerContainerDark,
    onDangerContainer: AppColors.onDangerContainerDark,
    info: AppColors.info,
    infoText: AppColors.infoTextDark,
    infoSoft: AppColors.infoSoftDark,
    infoContainer: AppColors.infoContainerDark,
    onInfoContainer: AppColors.onInfoContainerDark,
    ratingAgain: AppColors.ratingAgain,
    ratingAgainSoft: AppColors.ratingAgainSoft,
    ratingHard: AppColors.ratingHard,
    ratingHardSoft: AppColors.ratingHardSoft,
    ratingGood: AppColors.ratingGood,
    ratingGoodSoft: AppColors.ratingGoodSoft,
    ratingEasy: AppColors.ratingEasy,
    ratingEasySoft: AppColors.ratingEasySoft,
  );

  static AppPalette light() => lightPalette;

  static AppPalette dark() => darkPalette;

  final Color primary;
  final Color primaryDark;
  final Color primaryBright;
  final Color primaryPressed;
  final Color primarySoft;
  final Color primarySoftAlt;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceMuted;
  final Color surfaceMutedStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnPrimary;
  final Color textOnSurface;
  final Color border;
  final Color borderStrong;
  final Color outline;
  final Color outlineVariant;
  final Color success;
  final Color successText;
  final Color successSoft;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningText;
  final Color warningSoft;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color dangerText;
  final Color dangerSoft;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color info;
  final Color infoText;
  final Color infoSoft;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color ratingAgain;
  final Color ratingAgainSoft;
  final Color ratingHard;
  final Color ratingHardSoft;
  final Color ratingGood;
  final Color ratingGoodSoft;
  final Color ratingEasy;
  final Color ratingEasySoft;

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryBright,
    Color? primaryPressed,
    Color? primarySoft,
    Color? primarySoftAlt,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? background,
    Color? surface,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? surfaceMuted,
    Color? surfaceMutedStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnPrimary,
    Color? textOnSurface,
    Color? border,
    Color? borderStrong,
    Color? outline,
    Color? outlineVariant,
    Color? success,
    Color? successText,
    Color? successSoft,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningText,
    Color? warningSoft,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? dangerText,
    Color? dangerSoft,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? info,
    Color? infoText,
    Color? infoSoft,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? ratingAgain,
    Color? ratingAgainSoft,
    Color? ratingHard,
    Color? ratingHardSoft,
    Color? ratingGood,
    Color? ratingGoodSoft,
    Color? ratingEasy,
    Color? ratingEasySoft,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryBright: primaryBright ?? this.primaryBright,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primarySoft: primarySoft ?? this.primarySoft,
      primarySoftAlt: primarySoftAlt ?? this.primarySoftAlt,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceMutedStrong: surfaceMutedStrong ?? this.surfaceMutedStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      textOnSurface: textOnSurface ?? this.textOnSurface,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      successSoft: successSoft ?? this.successSoft,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      warningSoft: warningSoft ?? this.warningSoft,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      danger: danger ?? this.danger,
      dangerText: dangerText ?? this.dangerText,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      info: info ?? this.info,
      infoText: infoText ?? this.infoText,
      infoSoft: infoSoft ?? this.infoSoft,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      ratingAgain: ratingAgain ?? this.ratingAgain,
      ratingAgainSoft: ratingAgainSoft ?? this.ratingAgainSoft,
      ratingHard: ratingHard ?? this.ratingHard,
      ratingHardSoft: ratingHardSoft ?? this.ratingHardSoft,
      ratingGood: ratingGood ?? this.ratingGood,
      ratingGoodSoft: ratingGoodSoft ?? this.ratingGoodSoft,
      ratingEasy: ratingEasy ?? this.ratingEasy,
      ratingEasySoft: ratingEasySoft ?? this.ratingEasySoft,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: l(primary, other.primary),
      primaryDark: l(primaryDark, other.primaryDark),
      primaryBright: l(primaryBright, other.primaryBright),
      primaryPressed: l(primaryPressed, other.primaryPressed),
      primarySoft: l(primarySoft, other.primarySoft),
      primarySoftAlt: l(primarySoftAlt, other.primarySoftAlt),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      onPrimaryContainer: l(onPrimaryContainer, other.onPrimaryContainer),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceContainerLowest: l(
        surfaceContainerLowest,
        other.surfaceContainerLowest,
      ),
      surfaceContainerLow: l(surfaceContainerLow, other.surfaceContainerLow),
      surfaceContainer: l(surfaceContainer, other.surfaceContainer),
      surfaceContainerHigh: l(surfaceContainerHigh, other.surfaceContainerHigh),
      surfaceContainerHighest: l(
        surfaceContainerHighest,
        other.surfaceContainerHighest,
      ),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      surfaceMutedStrong: l(surfaceMutedStrong, other.surfaceMutedStrong),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textOnPrimary: l(textOnPrimary, other.textOnPrimary),
      textOnSurface: l(textOnSurface, other.textOnSurface),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      outline: l(outline, other.outline),
      outlineVariant: l(outlineVariant, other.outlineVariant),
      success: l(success, other.success),
      successText: l(successText, other.successText),
      successSoft: l(successSoft, other.successSoft),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      warningText: l(warningText, other.warningText),
      warningSoft: l(warningSoft, other.warningSoft),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      danger: l(danger, other.danger),
      dangerText: l(dangerText, other.dangerText),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      onDangerContainer: l(onDangerContainer, other.onDangerContainer),
      info: l(info, other.info),
      infoText: l(infoText, other.infoText),
      infoSoft: l(infoSoft, other.infoSoft),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      ratingAgain: l(ratingAgain, other.ratingAgain),
      ratingAgainSoft: l(ratingAgainSoft, other.ratingAgainSoft),
      ratingHard: l(ratingHard, other.ratingHard),
      ratingHardSoft: l(ratingHardSoft, other.ratingHardSoft),
      ratingGood: l(ratingGood, other.ratingGood),
      ratingGoodSoft: l(ratingGoodSoft, other.ratingGoodSoft),
      ratingEasy: l(ratingEasy, other.ratingEasy),
      ratingEasySoft: l(ratingEasySoft, other.ratingEasySoft),
    );
  }
}

/// Truy cập nhanh bảng màu theo theme: `context.appColors.textPrimary`.
extension AppPaletteContextX on BuildContext {
  AppPalette get appColors => AppPalette.of(this);
}

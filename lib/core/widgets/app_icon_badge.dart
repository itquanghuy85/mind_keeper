import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

enum AppIconTone { primary, success, warning, danger, info, neutral, surface }

/// Ô icon bo góc nền mềm — thay cho các vòng tròn icon rải rác từng màn hình.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.tone = AppIconTone.primary,
    this.size = AppSizes.badgeMd,
    this.radius = AppRadius.lg,
    this.color,
    this.background,
    this.iconSize,
  });

  final IconData icon;
  final AppIconTone tone;
  final double size;
  final double radius;
  final Color? color;
  final Color? background;
  final double? iconSize;

  (Color, Color) get _toneColors => switch (tone) {
    AppIconTone.primary => (AppColors.primary, AppColors.primarySoft),
    AppIconTone.success => (AppColors.success, AppColors.successSoft),
    AppIconTone.warning => (AppColors.warning, AppColors.warningSoft),
    AppIconTone.danger => (AppColors.danger, AppColors.dangerSoft),
    AppIconTone.info => (AppColors.info, AppColors.infoSoft),
    AppIconTone.neutral => (AppColors.textSecondary, AppColors.surfaceMuted),
    AppIconTone.surface => (AppColors.primary, AppColors.primarySoft),
  };

  @override
  Widget build(BuildContext context) {
    final (Color toneColor, Color toneBackground) = _toneColors;
    final Color foreground = color ?? toneColor;
    final double resolvedIconSize =
        iconSize ??
        switch (size) {
          <= AppSizes.badgeSm => 18,
          <= AppSizes.badgeMd => 20,
          _ => 24,
        };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? toneBackground,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: resolvedIconSize, color: foreground),
    );
  }
}

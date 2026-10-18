import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Chip lọc/hành động: bo góc 16, cao 36, trạng thái chọn rõ ràng.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.count,
    this.semanticsLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? count;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final Color background = selected ? AppColors.primary : AppColors.surface;
    final Color foreground = selected ? Colors.white : AppColors.textSecondary;
    final Color borderColor = selected ? AppColors.primary : AppColors.border;

    final Widget chip = Material(
      color: background,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          height: AppSizes.chipHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppSizes.iconXs, color: foreground),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: foreground,
                ),
              ),
              if (count != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs + 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.surfaceContainerHigh,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        container: true,
        label: semanticsLabel,
        child: chip,
      );
    }
    return chip;
  }
}

enum AppTagTone { neutral, primary, success, warning, danger, info }

/// Nhãn trạng thái nhỏ (dạng pill) — dùng cho metadata, không phải nút bấm.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.tone = AppTagTone.neutral,
    this.icon,
  });

  final String label;
  final AppTagTone tone;
  final IconData? icon;

  (Color, Color) get _colors => switch (tone) {
        AppTagTone.neutral => (AppColors.surfaceContainerHigh, AppColors.textSecondary),
        AppTagTone.primary => (AppColors.primaryContainer, AppColors.onPrimaryContainer),
        AppTagTone.success => (AppColors.successContainer, AppColors.onSuccessContainer),
        AppTagTone.warning => (AppColors.warningContainer, AppColors.onWarningContainer),
        AppTagTone.danger => (AppColors.dangerContainer, AppColors.onDangerContainer),
        AppTagTone.info => (AppColors.infoContainer, AppColors.onInfoContainer),
      };

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 3.5,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
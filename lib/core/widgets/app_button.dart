import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

enum AppButtonVariant { primary, secondary, tonal, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.leading,
    this.expanded = true,
    this.loading = false,
    this.dense = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final Widget? leading;
  final bool expanded;
  final bool loading;
  final bool dense;
  final String? tooltip;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final Widget child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: _foregroundColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (leading != null) ...<Widget>[leading!, const SizedBox(width: AppSpacing.sm)],
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppSizes.iconSm, color: _foregroundColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dense ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: _foregroundColor,
                  ),
                ),
              ),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: _enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: _enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.textTertiary,
            side: const BorderSide(color: AppColors.borderStrong),
          ),
          child: child,
        ),
      AppButtonVariant.tonal => FilledButton(
          onPressed: _enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.surfaceMuted,
            disabledForegroundColor: AppColors.textTertiary,
          ),
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: _enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white,
          ),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: _enabled ? onPressed : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: child,
        ),
    };

    final Widget sized = expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: sized);
    }
    return sized;
  }

  Color get _foregroundColor => switch (variant) {
        AppButtonVariant.primary || AppButtonVariant.danger => Colors.white,
        AppButtonVariant.secondary || AppButtonVariant.ghost => AppColors.primary,
        AppButtonVariant.tonal => AppColors.primary,
      };
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.filled = false,
    this.tone = AppIconTone.neutral,
    this.size = AppSizes.touchTarget,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool filled;
  final AppIconTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color background = switch (tone) {
      AppIconTone.neutral => filled ? AppColors.primarySoft : Colors.transparent,
      AppIconTone.primary => AppColors.primary,
      AppIconTone.surface => AppColors.surfaceMuted,
      AppIconTone.danger => AppColors.dangerSoft,
    };
    final Color foreground = switch (tone) {
      AppIconTone.neutral => AppColors.textPrimary,
      AppIconTone.primary => Colors.white,
      AppIconTone.surface => AppColors.textSecondary,
      AppIconTone.danger => AppColors.danger,
    };

    final Widget child = Icon(
      icon,
      size: AppSizes.iconMd,
      color: onPressed == null ? AppColors.textTertiary : foreground,
    );

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

enum AppIconTone { neutral, primary, surface, danger }

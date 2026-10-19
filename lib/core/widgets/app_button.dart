import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'app_icon_badge.dart';
import '../theme/app_palette.dart';

enum AppButtonVariant { primary, secondary, tonal, danger, ghost, fab }

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
  }) : isFab = false;

  const AppButton.fab({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.fab,
    this.icon,
    this.loading = false,
    this.tooltip,
  }) : expanded = true,
       dense = false,
       leading = null,
       isFab = true;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final Widget? leading;
  final bool expanded;
  final bool loading;
  final bool dense;
  final String? tooltip;
  final bool isFab;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = _labelColor(context);
    final double fontSize = dense ? 13.5 : 15;

    final Widget child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: labelColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: dense ? AppSizes.iconXs : AppSizes.iconSm,
                  color: labelColor,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          );

    final ButtonStyle? sizeStyle = dense ? _denseStyle : null;

    final Widget button = isFab
        ? FloatingActionButton.extended(
            onPressed: _enabled ? onPressed : null,
            icon: icon != null
                ? Icon(icon!, size: 24, color: labelColor)
                : null,
            label: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: labelColor,
              ),
            ),
            backgroundColor: _enabled
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.38),
            foregroundColor: labelColor,
            elevation: _enabled ? 2 : 0,
            focusElevation: 2,
            hoverElevation: 2,
            highlightElevation: 2,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
          )
        : switch (variant) {
            AppButtonVariant.primary || AppButtonVariant.fab => FilledButton(
              onPressed: _enabled ? onPressed : null,
              style: sizeStyle,
              child: child,
            ),
            AppButtonVariant.secondary => OutlinedButton(
              onPressed: _enabled ? onPressed : null,
              style: sizeStyle,
              child: child,
            ),
            AppButtonVariant.tonal => FilledButton(
              onPressed: _enabled ? onPressed : null,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.disabled)) {
                    return context.appColors.surfaceContainerHigh;
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return context.appColors.primarySoftAlt;
                  }
                  return context.appColors.primaryContainer;
                }),
                foregroundColor: WidgetStatePropertyAll<Color>(
                  context.appColors.onPrimaryContainer,
                ),
                overlayColor: WidgetStatePropertyAll<Color>(
                  AppColors.primary.withValues(alpha: 0.08),
                ),
                elevation: const WidgetStatePropertyAll<double>(0),
                shape: const WidgetStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
                ),
              ).merge(sizeStyle),
              child: child,
            ),
            AppButtonVariant.danger => FilledButton(
              onPressed: _enabled ? onPressed : null,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(WidgetState.disabled)) {
                    return AppColors.danger.withValues(alpha: 0.38);
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return Color.lerp(AppColors.danger, Colors.black, 0.14)!;
                  }
                  return AppColors.danger;
                }),
                foregroundColor: const WidgetStatePropertyAll<Color>(
                  Colors.white,
                ),
                overlayColor: WidgetStatePropertyAll<Color>(
                  Colors.white.withValues(alpha: 0.08),
                ),
                elevation: const WidgetStatePropertyAll<double>(0),
                shape: const WidgetStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
                ),
              ).merge(sizeStyle),
              child: child,
            ),
            AppButtonVariant.ghost => TextButton(
              onPressed: _enabled ? onPressed : null,
              style: sizeStyle == null
                  ? null
                  : const ButtonStyle()
                        .merge(sizeStyle)
                        .copyWith(
                          padding:
                              const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                                EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                        ),
              child: child,
            ),
          };

    final Widget sized = isFab
        ? button
        : expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: sized);
    }
    return sized;
  }

  static const ButtonStyle _denseStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll<Size>(
      Size(0, AppSizes.controlHeightSm),
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    ),
  );

  Color _labelColor(BuildContext context) {
    if (!_enabled) {
      return switch (variant) {
        AppButtonVariant.primary ||
        AppButtonVariant.danger ||
        AppButtonVariant.fab => Colors.white,
        AppButtonVariant.secondary ||
        AppButtonVariant.tonal ||
        AppButtonVariant.ghost => context.appColors.textTertiary,
      };
    }
    return switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => Colors.white,
      AppButtonVariant.secondary => context.appColors.primaryDark,
      AppButtonVariant.tonal => context.appColors.onPrimaryContainer,
      AppButtonVariant.ghost => context.appColors.primary,
      AppButtonVariant.fab => Colors.white,
    };
  }
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
      AppIconTone.neutral =>
        filled ? context.appColors.primarySoft : Colors.transparent,
      AppIconTone.primary => AppColors.primary,
      AppIconTone.surface => context.appColors.surfaceMuted,
      AppIconTone.danger => context.appColors.dangerSoft,
      AppIconTone.success => context.appColors.successSoft,
      AppIconTone.warning => context.appColors.warningSoft,
      AppIconTone.info => context.appColors.infoSoft,
    };
    final Color foreground = switch (tone) {
      AppIconTone.neutral => context.appColors.textPrimary,
      AppIconTone.primary => Colors.white,
      AppIconTone.surface => context.appColors.textSecondary,
      AppIconTone.danger => AppColors.danger,
      AppIconTone.success => AppColors.success,
      AppIconTone.warning => AppColors.warning,
      AppIconTone.info => AppColors.info,
    };

    final Widget child = Icon(
      icon,
      size: AppSizes.iconMd,
      color: onPressed == null ? context.appColors.textTertiary : foreground,
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

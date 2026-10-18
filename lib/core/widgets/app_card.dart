import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Thẻ nội dung chuẩn: nền trắng, viền mảnh, bóng mờ nhẹ, bo góc 16.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color = AppColors.surface,
    this.border,
    this.radius = AppRadius.lg,
    this.highlighted = false,
    this.elevated = false,
    this.semanticsLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color color;
  final Color? border;
  final double radius;
  final bool highlighted;

  /// Bóng đậm hơn cho thẻ nổi bật (hero, thẻ ôn tập...).
  final bool elevated;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final Color effectiveBorder =
        border ?? (highlighted ? AppColors.primary : AppColors.border);

    final Widget content = Padding(padding: padding, child: child);

    final Widget card = Padding(
      padding: margin,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: effectiveBorder,
                width: highlighted ? 1.4 : AppSizes.dividerThickness,
              ),
              boxShadow: <BoxShadow>[
                if (elevated)
                  const BoxShadow(
                    color: AppColors.shadowStrong,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  )
                else
                  const BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        container: true,
        label: semanticsLabel,
        child: card,
      );
    }
    return card;
  }
}

/// Tiêu đề mục + hành động phụ (kiểu "Xem tất cả").
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              borderRadius: AppRadius.smAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
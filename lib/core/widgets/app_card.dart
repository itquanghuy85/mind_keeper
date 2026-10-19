import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// Thẻ nội dung chuẩn: nền trắng, viền mảnh, bóng mờ nhẹ, bo góc 16.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
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
  final Color? color;
  final Color? border;
  final double radius;
  final bool highlighted;

  /// Bóng đậm hơn cho thẻ nổi bật (hero, thẻ ôn tập...).
  final bool elevated;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final Color effectiveBorder =
        border ??
        (highlighted ? context.appColors.primary : context.appColors.border);
    final Color effectiveColor = color ?? context.appColors.surface;
    final BorderRadius shape = BorderRadius.circular(radius);

    final Widget content = Padding(padding: padding, child: child);

    // Bóng đổ phải nằm NGOÀI thẻ: vẽ shadow ở lớp ngoài (DecoratedBox) rồi phủ
    // lớp Material ĐỤC lên trên. Nếu gắn boxShadow vào chính lớp chứa nội dung
    // (lớp không có màu nền), shadow translucent bị nhìn xuyên qua toàn bộ mặt
    // thẻ → thẻ trắng thành xám (#EEEFF0) và bóng lem cả vào khe giữa các thẻ.
    final Widget card = Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: <BoxShadow>[
            if (elevated)
              const BoxShadow(
                color: AppColors.shadowStrong,
                blurRadius: 20,
                spreadRadius: -4,
                offset: Offset(0, 6),
              )
            else
              const BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                spreadRadius: -4,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: effectiveColor,
          borderRadius: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: shape,
            splashColor: AppColors.primary.withValues(alpha: 0.06),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: shape,
                border: Border.all(
                  color: effectiveBorder,
                  width: highlighted ? 1.4 : AppSizes.dividerThickness,
                ),
              ),
              child: content,
            ),
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
      // Wrap thay vì Row: khi cỡ chữ lớn (font scale ≥ 1.5–2.0×) nhãn hành động
      // không vừa một dòng với tiêu đề, nó tự xuống dòng thay vì tràn ra ngoài.
      // Khi vừa đủ, bố cục vẫn là tiêu đề trái – hành động phải.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: AppSpacing.xs,
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
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
                  style: TextStyle(
                    color: context.appColors.primary,
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

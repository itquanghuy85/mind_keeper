import 'package:flutter/material.dart';

import 'app_dimens.dart';

/// Bộ màu biểu đồ dùng chung, tự điều chỉnh theo light/dark theme qua
/// [Theme.of(context)]. Không tạo palette riêng cho từng màn hình.
abstract class AppChartTheme {
  /// Màu đường/chân chữ chính của biểu đồ (dùng cho bar, line, pie).
  static Color lineColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Màu nền của vùng vẽ biểu đồ (grid background).
  static Color gridBackground(BuildContext context) => Theme.of(
    context,
  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

  /// Màu lưới và trục.
  static Color gridLine(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  /// Màu text nhãn trục (x, y).
  static Color axisLabel(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Màu tooltip nền.
  static Color tooltipBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Màu text tooltip.
  static Color tooltipText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Màu viền tooltip.
  static Color tooltipBorder(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  /// Màu chuỗi dữ liệu thứ 2 (dùng khi cần phân biệt hai chuỗi).
  static Color series2Color(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  /// Màu chuỗi dữ liệu thứ 3.
  static Color series3Color(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;

  /// Màu nền cho trạng thái rỗng của biểu đồ.
  static Color emptyBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  /// Màu biểu tượng trạng thái rỗng.
  static Color emptyIcon(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Màu tiêu đề biểu đồ.
  static Color title(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Màu chú thích (legend).
  static Color legend(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Màu nền của thẻ chứa biểu đồ.
  static Color cardBackground(BuildContext context) =>
      Theme.of(context).cardColor;

  /// Màu viền của thẻ chứa biểu đồ.
  static Color cardBorder(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  /// Bán kính bo góc cho thẻ biểu đồ.
  static double get cardRadius => AppRadius.lg;

  /// Khoảng cách padding bên trong thẻ biểu đồ.
  static EdgeInsetsGeometry get cardPadding =>
      const EdgeInsets.all(AppSpacing.md);

  /// Màu thanh progress (linear) dùng trong biểu đồ tóm tắt.
  static Color progressTrack(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  /// Độ cao tối thiểu của bar khi giá trị là 0 (tránh mất hiển thị).
  static double get minBarHeight => 4;

  /// Chiều rộng của mỗi bar.
  static double get barWidth => 24;

  /// Khoảng cách giữa các bar.
  static double get barSpacing => 16;

  /// Bo góc đầu bar.
  static double get barRadius => 4;
}

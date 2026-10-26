import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Màu thương hiệu dùng chung cho icon, màn hình khởi động và tài liệu cửa hàng.
abstract final class BrandColors {
  static const Color indigo = Color(0xFF6D5DF6);
  static const Color blue = Color(0xFF2F6FED);
  static const Color deep = Color(0xFF1E2A78);
  static const Color spark = Color(0xFFFFC857);
}

/// Biến thể vẽ logo.
enum BrandVariant {
  /// Ô vuông bo góc, nền chuyển màu — icon Android thường / Play Store.
  rounded,

  /// Ô vuông tràn viền, không trong suốt — icon iOS / App Store.
  fullBleed,

  /// Chỉ ký hiệu trên nền trong suốt — lớp trước của adaptive icon (vùng an toàn).
  foreground,

  /// Chỉ ký hiệu, kích thước đầy đủ — màn hình khởi động / logo.
  mark,
}

/// Logo MindKeeper: chữ M nét tròn (hai trang sách mở) + tia sáng kiến thức.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({
    this.variant = BrandVariant.rounded,
    this.markColor = Colors.white,
    this.sparkProgress = 1,
  });

  final BrandVariant variant;
  final Color markColor;

  /// 0..1: độ lớn của tia sáng (dùng cho hoạt ảnh khởi động).
  final double sparkProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Rect full = Offset.zero & size;

    switch (variant) {
      case BrandVariant.rounded:
        _background(canvas, full, radius: s * 0.225);
      case BrandVariant.fullBleed:
        _background(canvas, full, radius: 0);
      case BrandVariant.foreground:
      case BrandVariant.mark:
        break;
    }

    // Ký hiệu nằm gọn trong vùng an toàn 66% của adaptive icon.
    final double scale = switch (variant) {
      BrandVariant.foreground => 0.62,
      BrandVariant.mark => 0.9,
      _ => 0.74,
    };
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.scale(s * scale / 100);
    _paintMark(canvas);
    canvas.restore();
  }

  void _background(Canvas canvas, Rect rect, {required double radius}) {
    final RRect shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[BrandColors.indigo, BrandColors.blue],
        ).createShader(rect),
    );
    // Ánh sáng nhẹ góc trên-trái cho cảm giác chiều sâu.
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawCircle(
      Offset(rect.width * 0.22, rect.height * 0.16),
      rect.width * 0.62,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(rect.width * 0.22, rect.height * 0.16),
            radius: rect.width * 0.62,
          ),
        ),
    );
    canvas.restore();
  }

  /// Vẽ trong hệ toạ độ 100×100 căn giữa gốc (0,0).
  void _paintMark(Canvas canvas) {
    final Path m = Path()
      ..moveTo(-33, 30)
      ..lineTo(-33, -28)
      ..lineTo(0, 8)
      ..lineTo(33, -28)
      ..lineTo(33, 30);

    // Bóng đổ mềm dưới chữ M.
    canvas.save();
    canvas.translate(0, 3.2);
    canvas.drawPath(
      m,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = BrandColors.deep.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );
    canvas.restore();

    canvas.drawPath(
      m,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = markColor,
    );

    // Điểm nhớ ở đáy chữ M (viên ngọc kiến thức).
    canvas.drawCircle(
      const Offset(0, 30),
      6.4,
      Paint()..color = markColor.withValues(alpha: 0.92),
    );

    if (sparkProgress > 0) {
      _spark(canvas, const Offset(41, -43), 15 * sparkProgress);
    }
  }

  void _spark(Canvas canvas, Offset c, double r) {
    final Path star = Path();
    const int points = 4;
    for (int i = 0; i < points * 2; i++) {
      final double angle = -math.pi / 2 + i * math.pi / points;
      final double radius = i.isEven ? r : r * 0.26;
      final Offset p = Offset(
        c.dx + math.cos(angle) * radius,
        c.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..color = BrandColors.spark
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      star,
      Paint()
        ..color = BrandColors.spark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.variant != variant ||
      old.markColor != markColor ||
      old.sparkProgress != sparkProgress;
}

/// Logo MindKeeper dạng widget.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 96,
    this.variant = BrandVariant.rounded,
    this.markColor = Colors.white,
    this.sparkProgress = 1,
  });

  final double size;
  final BrandVariant variant;
  final Color markColor;
  final double sparkProgress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: BrandMarkPainter(
            variant: variant,
            markColor: markColor,
            sparkProgress: sparkProgress,
          ),
        ),
      ),
    );
  }
}

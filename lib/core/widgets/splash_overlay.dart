import 'package:flutter/material.dart';

import 'brand_mark.dart';

/// Màn hình khởi động trong app: nối liền với màn hình khởi động của hệ điều
/// hành (cùng nền chuyển màu + cùng logo), tia sáng nảy ra rồi mờ dần để lộ
/// trang chủ. Chỉ để nhìn — không chặn chạm.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final bool enabled;
  final Duration duration;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              final double t = _controller.value;
              if (t >= 1) return const SizedBox.shrink();
              // 0–0.55: hiện đủ · 0.55–1: mờ dần.
              final double fade = t < 0.55
                  ? 1
                  : 1 - Curves.easeInOut.transform((t - 0.55) / 0.45);
              final double spark = Curves.easeOutBack.transform(
                (t / 0.35).clamp(0.0, 1.0),
              );
              final double text = Curves.easeOut.transform(
                ((t - 0.15) / 0.3).clamp(0.0, 1.0),
              );
              return Opacity(
                opacity: fade,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[BrandColors.indigo, BrandColors.blue],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        BrandMark(
                          size: 148,
                          variant: BrandVariant.mark,
                          sparkProgress: spark,
                        ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: text,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - text)),
                            child: Column(
                              children: <Widget>[
                                const Text(
                                  'MindKeeper',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Mỗi ngày nhớ thêm một chút',
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: 0.85,
                                    ),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

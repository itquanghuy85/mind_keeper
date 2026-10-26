// Sinh icon, logo khởi động, ảnh đồ họa và ảnh chụp màn hình cho cửa hàng.
//
// Chạy (từ thư mục gốc dự án):
//   flutter test tool/brand/render_brand_test.dart --dart-define=BRAND_OUT=<thư mục dự án>
// Nếu có ảnh chụp thật trong store/raw_screenshots/*.png thì ghép thêm khung
// tiếp thị vào store/screenshots/ (Android + iPhone 6.7" + iPad 12.9").
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/widgets/brand_mark.dart';

const String _out = String.fromEnvironment('BRAND_OUT');

Future<void> _loadFonts() async {
  final FontLoader loader = FontLoader('Inter');
  for (final String w in <String>['400', '500', '600', '700']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
  }
  await loader.load();
}

Future<void> _save(
  WidgetTester tester,
  Widget child,
  Size size,
  String relativePath,
) async {
  final GlobalKey key = GlobalKey();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: RepaintBoundary(key: key, child: child),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final File file = File('$_out/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
  });
}

Widget _icon(BrandVariant v, double size) =>
    SizedBox(width: size, height: size, child: BrandMark(size: size, variant: v));

TextStyle _t(double size, FontWeight w, {Color color = Colors.white}) =>
    TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: w,
      color: color,
      decoration: TextDecoration.none,
      height: 1.2,
    );

Widget _gradient({required Widget child}) => DecoratedBox(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[BrandColors.indigo, BrandColors.blue],
    ),
  ),
  child: child,
);

/// Khung tiếp thị: nền thương hiệu + tiêu đề + ảnh chụp thật (đã cắt thanh
/// trạng thái) trong khung bo góc, tràn xuống mép dưới.
Widget _frame(ui.Image shot, String caption, Size size) {
  final double phoneW = size.width * 0.76;
  final double k = phoneW / 820;
  final double radius = 64 * k;
  return _gradient(
    child: Stack(
      children: <Widget>[
        Positioned(
          left: size.width * 0.05,
          right: size.width * 0.05,
          top: size.height * 0.055,
          child: Text(
            caption,
            textAlign: TextAlign.center,
            style: _t(size.width * 0.063, FontWeight.w700),
          ),
        ),
        Positioned(
          left: (size.width - phoneW) / 2,
          width: phoneW,
          top: size.height * 0.172,
          bottom: -size.height * 0.04,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 60,
                  offset: Offset(0, 24),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    top: -78 * k,
                    width: phoneW,
                    height: phoneW * shot.height / shot.width,
                    child: RawImage(image: shot, fit: BoxFit.fill),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('icon + logo', (WidgetTester tester) async {
    expect(_out, isNotEmpty, reason: 'Cần --dart-define=BRAND_OUT=<dự án>');
    await _save(
      tester,
      _icon(BrandVariant.rounded, 1024),
      const Size(1024, 1024),
      'assets/images/app_icon.png',
    );
    await _save(
      tester,
      _icon(BrandVariant.fullBleed, 1024),
      const Size(1024, 1024),
      'assets/images/app_icon_ios.png',
    );
    await _save(
      tester,
      _icon(BrandVariant.foreground, 1024),
      const Size(1024, 1024),
      'assets/images/app_icon_adaptive.png',
    );
    await _save(
      tester,
      BrandMark(size: 512, variant: BrandVariant.mark),
      const Size(512, 512),
      'assets/images/splash_logo.png',
    );
    // Màn hình khởi động native: Android (drawable) + iOS (LaunchImage).
    await _save(
      tester,
      BrandMark(size: 360, variant: BrandVariant.mark),
      const Size(360, 360),
      'android/app/src/main/res/drawable-xxhdpi/splash_logo.png',
    );
    await _save(
      tester,
      BrandMark(size: 960, variant: BrandVariant.foreground),
      const Size(960, 960),
      'android/app/src/main/res/drawable-nodpi/splash_android12.png',
    );
    for (final (String, double) f in <(String, double)>[
      ('LaunchImage.png', 168),
      ('LaunchImage@2x.png', 336),
      ('LaunchImage@3x.png', 504),
    ]) {
      await _save(
        tester,
        BrandMark(size: f.$2, variant: BrandVariant.mark),
        Size(f.$2, f.$2),
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/${f.$1}',
      );
    }
    // Tài liệu cửa hàng.
    await _save(
      tester,
      _icon(BrandVariant.rounded, 512),
      const Size(512, 512),
      'store/play/icon_512.png',
    );
    await _save(
      tester,
      _icon(BrandVariant.fullBleed, 1024),
      const Size(1024, 1024),
      'store/appstore/icon_1024.png',
    );
  });

  testWidgets('feature graphic Google Play', (WidgetTester tester) async {
    await _save(
      tester,
      _gradient(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 90),
          child: Row(
            children: <Widget>[
              _icon(BrandVariant.rounded, 300),
              const SizedBox(width: 56),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('MindKeeper', style: _t(68, FontWeight.w700)),
                    const SizedBox(height: 14),
                    Text(
                      'Mỗi ngày nhớ thêm một chút',
                      style: _t(31, FontWeight.w500),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Chọn chủ đề · AI soạn lộ trình\nNhắc đọc & ôn đúng lúc',
                      style: _t(24, FontWeight.w400,
                          color: const Color(0xCCFFFFFF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const Size(1024, 500),
      'store/play/feature_graphic_1024x500.png',
    );
  });

  testWidgets('khung mở đầu/kết video giới thiệu', (WidgetTester tester) async {
    Widget title(String line1, String line2) => _gradient(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BrandMark(size: 300, variant: BrandVariant.mark),
            const SizedBox(height: 40),
            Text(line1, style: _t(88, FontWeight.w700)),
            const SizedBox(height: 16),
            Text(
              line2,
              textAlign: TextAlign.center,
              style: _t(40, FontWeight.w500, color: const Color(0xDDFFFFFF)),
            ),
          ],
        ),
      ),
    );
    await _save(
      tester,
      title('MindKeeper', 'Mỗi ngày nhớ thêm một chút'),
      const Size(1080, 1920),
      'store/video/frames/00_intro.png',
    );
    await _save(
      tester,
      title('Học ít, nhớ lâu', 'Chọn chủ đề · AI soạn lộ trình · Nhắc đúng lúc'),
      const Size(1080, 1920),
      'store/video/frames/99_outro.png',
    );
  });

  // Khung tiếp thị từ ảnh chụp thật (nếu có).
  final Directory raw = Directory('$_out/store/raw_screenshots');
  final List<File> shots = raw.existsSync()
      ? (raw
            .listSync()
            .whereType<File>()
            .where((File f) => f.path.endsWith('.png'))
            .toList()
          ..sort((File a, File b) => a.path.compareTo(b.path)))
      : <File>[];
  const Map<String, String> captions = <String, String>{
    '01': 'Một việc chính mỗi ngày',
    '02': 'Chọn cấp độ và số mẩu',
    '03': 'AI soạn đề cương, bạn chỉnh',
    '04': 'Đọc ngắn, hiểu ngay',
    '05': 'Theo dõi tiến độ từng khóa',
  };
  const List<(String, Size)> targets = <(String, Size)>[
    ('android_phone', Size(1080, 1920)),
    ('ios_6.7', Size(1290, 2796)),
    ('ios_6.5', Size(1284, 2778)),
    ('ios_5.5', Size(1242, 2208)),
    ('ipad_12.9', Size(2048, 2732)),
  ];
  for (final File f in shots) {
    final String name = f.uri.pathSegments.last.replaceAll('.png', '');
    final String prefix = name.split('_').first;
    testWidgets('khung tiếp thị $name', (WidgetTester tester) async {
      late final ui.Image decoded;
      await tester.runAsync(() async {
        final ui.Codec codec = await ui.instantiateImageCodec(
          await f.readAsBytes(),
        );
        decoded = (await codec.getNextFrame()).image;
      });
      for (final (String, Size) t in targets) {
        await _save(
          tester,
          _frame(decoded, captions[prefix] ?? name, t.$2),
          t.$2,
          'store/screenshots/${t.$1}/$name.png',
        );
      }
    });
  }
}

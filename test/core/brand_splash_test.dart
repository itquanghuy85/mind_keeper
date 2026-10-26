import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/widgets/brand_mark.dart';
import 'package:mind_keeper/core/widgets/splash_overlay.dart';

void main() {
  testWidgets('SplashOverlay hiện logo + tên rồi tự biến mất, không chặn chạm', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashOverlay(
          duration: const Duration(milliseconds: 800),
          child: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => taps++,
                child: const Text('Nút bên dưới'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('MindKeeper'), findsOneWidget);
    expect(find.byType(BrandMark), findsOneWidget);
    // Chạm xuyên qua lớp splash (chỉ để nhìn).
    await tester.tap(find.text('Nút bên dưới'));
    expect(taps, 1);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('MindKeeper'), findsNothing);
    expect(find.text('Nút bên dưới'), findsOneWidget);
  });

  testWidgets('SplashOverlay tắt được (dùng cho test)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashOverlay(enabled: false, child: Text('nội dung')),
      ),
    );
    expect(find.text('MindKeeper'), findsNothing);
    expect(find.text('nội dung'), findsOneWidget);
  });

  test('BrandMarkPainter: shouldRepaint theo biến thể / tia sáng', () {
    const BrandMarkPainter a = BrandMarkPainter();
    expect(a.shouldRepaint(const BrandMarkPainter()), isFalse);
    expect(
      a.shouldRepaint(const BrandMarkPainter(variant: BrandVariant.mark)),
      isTrue,
    );
    expect(a.shouldRepaint(const BrandMarkPainter(sparkProgress: 0.5)), isTrue);
  });
}

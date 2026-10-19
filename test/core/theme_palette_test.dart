import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/theme/app_palette.dart';
import 'package:mind_keeper/core/theme/app_theme.dart';

void main() {
  group('AppPalette — theme-aware (GĐ20)', () {
    test('AppTheme.light/dark đăng ký extension AppPalette', () {
      final AppPalette? light = AppTheme.light().extension<AppPalette>();
      final AppPalette? dark = AppTheme.dark().extension<AppPalette>();

      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
    });

    test('nền sáng ở light, tối ở dark; chữ tương phản tương ứng', () {
      expect(
        AppPalette.lightPalette.background.computeLuminance(),
        greaterThan(0.85),
      );
      expect(
        AppPalette.darkPalette.background.computeLuminance(),
        lessThan(0.20),
      );

      expect(
        AppPalette.lightPalette.textPrimary.computeLuminance(),
        lessThan(0.3),
      );
      expect(
        AppPalette.darkPalette.textPrimary.computeLuminance(),
        greaterThan(0.7),
      );
    });

    test('light và dark khác nhau ở các token chính', () {
      expect(
        AppPalette.lightPalette.background,
        isNot(AppPalette.darkPalette.background),
      );
      expect(
        AppPalette.lightPalette.primarySoft,
        isNot(AppPalette.darkPalette.primarySoft),
      );
      expect(
        AppPalette.lightPalette.surface,
        isNot(AppPalette.darkPalette.surface),
      );
      expect(
        AppPalette.lightPalette.textPrimary,
        isNot(AppPalette.darkPalette.textPrimary),
      );
    });

    test('lerp tạo giá trị trung gian giữa light và dark', () {
      final AppPalette mid = AppPalette.lightPalette.lerp(
        AppPalette.darkPalette,
        0.5,
      );
      expect(mid.background, isNot(AppPalette.lightPalette.background));
      expect(mid.background, isNot(AppPalette.darkPalette.background));
    });

    testWidgets('context.appColors lấy palette theo theme đang áp dụng', (
      WidgetTester tester,
    ) async {
      late AppPalette fromLight;
      late AppPalette fromDark;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              fromLight = context.appColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (BuildContext context) {
              fromDark = context.appColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // ThemeData được animate (lerp) giữa light/dark — phải settle để
      // extension trả giá trị cuối của theme dark.
      await tester.pumpAndSettle();

      expect(fromLight.background, AppPalette.lightPalette.background);
      expect(fromDark.background, AppPalette.darkPalette.background);
      expect(
        fromLight.background,
        isNot(fromDark.background),
        reason: 'nền light và dark phải khác nhau',
      );
    });
  });
}

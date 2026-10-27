import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mind_keeper/core/di/app_providers.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/models/course.dart';
import 'package:mind_keeper/features/ai/http_ai_provider.dart';
import 'package:mind_keeper/features/courses/add_course_screen.dart';
import 'package:mind_keeper/features/courses/course_reader_screen.dart';
import 'package:mind_keeper/features/home/today_screen.dart';
import 'package:mind_keeper/features/profile/privacy_screen.dart';

Future<AppServices> _build(WidgetTester tester) async {
  final AppServices? s = await tester.runAsync(() async {
    sqfliteFfiInit();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppDatabase app = AppDatabase(
      factory: databaseFactoryFfi,
      name: inMemoryDatabasePath,
    );
    await app.open();
    return AppServices.build(
      database: app,
      prefs: prefs,
      notifications: FakeNotificationService(),
    );
  });
  return s!;
}

Future<T> _db<T>(WidgetTester t, Future<T> Function() op) async =>
    (await t.runAsync(op)) as T;

Widget _wrap(AppServices s, Widget child) => MultiProvider(
  providers: buildAppProviders(s),
  child: MaterialApp(
    theme: ThemeData.light(),
    locale: const Locale('vi'),
    home: child,
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    if (!tester.binding.hasScheduledFrame) break;
  }
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pump(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(w);
  await _settle(tester);
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Provider HTTP giả: trả đề cương/mẩu hợp lệ — AiService coi là provider thật.
HttpAIProvider _fakeHttpAi() => HttpAIProvider(
  baseUrl: 'http://fake.local/v1',
  apiKey: 'k',
  model: 'm',
  client: MockClient((http.Request request) async {
    final Map<String, Object?> body =
        jsonDecode(utf8.decode(request.bodyBytes)) as Map<String, Object?>;
    final List<Object?> messages = body['messages']! as List<Object?>;
    final String system =
        ((messages.first! as Map<String, Object?>)['content'] ?? '')
            .toString();
    final String content;
    if (system.contains('lập đề cương')) {
      content = jsonEncode(<String, Object?>{
        'titles': <String>[
          'Bếp từ hoạt động thế nào?',
          'Vì sao nồi nhôm không dùng được?',
          'Vì sao mặt kính ít nóng?',
        ],
      });
    } else {
      content = jsonEncode(<String, Object?>{
        'title': 'Mẩu',
        'content': 'Nội dung đầy đủ của mẩu kiến thức này khá dài để đọc.',
        'summary': 'Tóm tắt ngắn.',
        'example': 'Ví dụ.',
        'sources': <String>['Giáo trình A'],
        'question': 'Câu hỏi?',
        'answer': 'Đáp án.',
      });
    }
    return http.Response.bytes(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'choices': <Object?>[
            <String, Object?>{
              'message': <String, Object?>{'content': content},
            },
          ],
        }),
      ),
      200,
      headers: <String, String>{'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

void main() {
  group('Trang chủ mới', () {
    testWidgets('có mẩu chưa đọc: thẻ chính + Chưa đọc + Đang theo', (
      WidgetTester tester,
    ) async {
      final AppServices s = await _build(tester);
      _phone(tester);
      await _db<void>(tester, () async {
        final course = await s.courseService.startCourse(
          topicName: 'Bếp từ',
          level: CourseLevel.advanced,
          titles: <String>['Mẩu một', 'Mẩu hai', 'Mẩu ba'],
        );
        // Sinh nội dung thật qua service có provider HTTP giả.
        s.ai.useProvider(_fakeHttpAi());
        await s.courseService.generateNext(course.id);
        await s.courseService.generateNext(course.id);
      });

      await _pump(tester, _wrap(s, const TodayScreen()));
      expect(tester.takeException(), isNull);
      expect(find.text('2 mẩu mới'), findsOneWidget);
      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(find.text('Chưa đọc'), findsOneWidget);
      expect(find.byTooltip('Thêm'), findsOneWidget);
      // Không còn các khối gây rối.
      expect(find.text('Nhanh tập trung'), findsNothing);
      expect(find.text('Tiến độ hôm nay'), findsNothing);
      expect(find.text('Chủ đề gần đây'), findsNothing);
      await tester.runAsync(s.dispose);
    });

    testWidgets('hết việc: "Xong cho hôm nay" + đọc trước', (
      WidgetTester tester,
    ) async {
      final AppServices s = await _build(tester);
      _phone(tester);
      await _db<void>(tester, () async {
        await s.courseService.startCourse(
          topicName: 'Bếp từ',
          level: CourseLevel.basic,
          titles: <String>['Mẩu một', 'Mẩu hai'],
        );
      });
      await _pump(tester, _wrap(s, const TodayScreen()));
      expect(find.text('Xong cho hôm nay'), findsOneWidget);
      expect(find.text('Đọc trước mẩu kế tiếp'), findsOneWidget);
      expect(find.text('Đang theo'), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
      await tester.runAsync(s.dispose);
    });

    testWidgets('chưa có khóa học: mời thêm khóa học', (
      WidgetTester tester,
    ) async {
      final AppServices s = await _build(tester);
      _phone(tester);
      await _pump(tester, _wrap(s, const TodayScreen()));
      expect(find.text('Học một chủ đề mới'), findsOneWidget);
      expect(find.text('Thêm khóa học'), findsOneWidget);
      await tester.runAsync(s.dispose);
    });
  });

  group('Thêm khóa học', () {
    testWidgets('AI chưa cấu hình: báo lỗi rõ, không cho bắt đầu', (
      WidgetTester tester,
    ) async {
      final AppServices s = await _build(tester);
      _phone(tester);
      await _pump(tester, _wrap(s, const AddCourseScreen()));
      expect(find.text('Chọn ít nhất 1 chủ đề'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Bếp từ');
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      await tester.tap(find.byTooltip('Thêm chủ đề'));
      await tester.pump();
      await tester.tap(find.text('Tiếp tục (1 chủ đề)'));
      await tester.pump();
      expect(find.text('Cấp độ và số mẩu'), findsWidgets);
      for (final String l in <String>['Cơ bản', 'Nâng cao', 'Pro', 'Master']) {
        expect(find.text(l), findsOneWidget);
      }
      await tester.tap(find.text('Soạn đề cương'));
      await _settle(tester);
      expect(find.textContaining('AI chưa được cấu hình'), findsOneWidget);
      final Finder start = find.widgetWithText(FilledButton, 'Bắt đầu học');
      if (start.evaluate().isNotEmpty) {
        expect(tester.widget<FilledButton>(start).onPressed, isNull);
      }
      await tester.runAsync(s.dispose);
    });

    testWidgets('luồng đầy đủ: đề cương → bỏ mục → bắt đầu tạo khóa học', (
      WidgetTester tester,
    ) async {
      final AppServices s = await _build(tester);
      s.ai.useProvider(_fakeHttpAi());
      _phone(tester);
      await _pump(tester, _wrap(s, const AddCourseScreen()));
      await tester.enterText(find.byType(TextField).first, 'Bếp từ');
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      await tester.tap(find.byTooltip('Thêm chủ đề'));
      await tester.pump();
      await tester.tap(find.text('Tiếp tục (1 chủ đề)'));
      await tester.pump();
      await tester.tap(find.text('Pro'));
      await tester.pump();
      await tester.tap(find.text('Soạn đề cương'));
      await _settle(tester);
      expect(find.text('Bếp từ hoạt động thế nào?'), findsOneWidget);
      // Bỏ mục thứ 3
      await tester.tap(find.byTooltip('Bỏ mục 3'));
      await tester.pump();
      expect(find.text('Vì sao mặt kính ít nóng?'), findsNothing);
      await tester.tap(find.text('Bắt đầu học'));
      await _settle(tester);

      final List<Course> courses = await _db(tester, s.courseRepo.list);
      expect(courses, hasLength(1));
      expect(courses.single.level, CourseLevel.pro);
      expect(courses.single.totalItems, 2);
      await tester.runAsync(s.dispose);
    });
  });

  group('Chọn lĩnh vực', () {
    testWidgets('chọn lĩnh vực rộng → thành chủ đề của khóa', (
      WidgetTester tester,
    ) async {
      final AppServices s = await _build(tester);
      _phone(tester);
      await _pump(tester, _wrap(s, const AddCourseScreen()));
      expect(find.text('Chọn lĩnh vực'), findsWidgets);
      await tester.tap(find.text('Y tế & sức khỏe'));
      await tester.tap(find.text('Nhân vật nổi tiếng'));
      await tester.pump();
      expect(find.text('Tiếp tục (2 chủ đề)'), findsOneWidget);
      await tester.runAsync(s.dispose);
    });
  });

  group('Đọc mẩu', () {
    testWidgets('Đã hiểu → xác nhận + nút đọc tiếp; Báo nội dung tạm dừng ôn', (
      WidgetTester tester,
    ) async {
      final AppServices s = await _build(tester);
      s.ai.useProvider(_fakeHttpAi());
      _phone(tester);
      final CourseItem item = await _db<CourseItem>(tester, () async {
        final course = await s.courseService.startCourse(
          topicName: 'Bếp từ',
          level: CourseLevel.basic,
          titles: <String>['Mẩu một', 'Mẩu hai'],
        );
        return (await s.courseService.generateNext(course.id))!;
      });
      await _pump(tester, _wrap(s, CourseReaderScreen(itemId: item.id)));
      expect(find.text('Đã hiểu'), findsOneWidget);
      expect(find.textContaining('Chưa kiểm chứng'), findsWidgets);

      await tester.tap(find.byTooltip('Báo nội dung'));
      await tester.pumpAndSettle();
      expect(find.text('Kiến thức sai hoặc gây hiểu lầm'), findsOneWidget);
      await tester.tap(find.text('Kiến thức sai hoặc gây hiểu lầm'));
      await _settle(tester);
      final paused = await _db(
        tester,
        () => s.knowledge.getById(item.knowledgeItemId!),
      );
      expect(paused!.isPaused, isTrue);
      await tester.pump(const Duration(seconds: 6)); // hết SnackBar

      await tester.tap(find.text('Đã hiểu'));
      await _settle(tester);
      expect(find.text('Đọc mẩu tiếp theo'), findsOneWidget);
      await tester.runAsync(s.dispose);
    });
  });

  testWidgets('Quyền riêng tư & điều khoản hiển thị đủ mục', (
    WidgetTester tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.light(), home: const PrivacyScreen()),
    );
    expect(find.text('Quyền riêng tư & điều khoản'), findsOneWidget);
    expect(find.text('Dữ liệu ở trên máy bạn'), findsOneWidget);
    expect(find.text('Khi dùng AI'), findsOneWidget);
    expect(
      find.text('Nội dung AI chưa kiểm chứng', skipOffstage: false),
      findsOneWidget,
    );
  });
}

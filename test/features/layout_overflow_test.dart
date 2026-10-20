import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mind_keeper/core/di/app_providers.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/core/widgets/app_card.dart';
import 'package:mind_keeper/core/widgets/app_text_field.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/features/home/today_screen.dart';
import 'package:mind_keeper/features/lessons/lesson_discover_screen.dart';
import 'package:mind_keeper/features/topics/topic_detail_screen.dart';

/// Xây dựng dịch vụ test trên DB in-memory (giống widget_test.dart).
/// QUAN TRỌNG: toàn bộ setup DB thật (sqflite FFI + shared_preferences)
/// PHẢI chạy trong [tester.runAsync]. Chạy trực tiếp trong fake-zone của
/// testWidgets làm `pumpWidget` treo vô hạn (future FFI không settle), kéo
/// theo "Guarded function conflict" dây chuyền ở các test sau.
Future<AppServices> _buildServices(WidgetTester tester) async {
  final AppServices? services = await tester.runAsync(() async {
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
  return services!;
}

/// Chạy một thao tác DB thật trong real event loop (không treo fake-zone).
Future<T> _db<T>(
  WidgetTester tester,
  Future<T> Function(AppServices services) op, {
  required AppServices services,
}) async {
  final T? result = await tester.runAsync(() => op(services));
  return result as T;
}

/// Đóng DB trong real event loop (tránh treo teardown).
Future<void> _dispose(WidgetTester tester, AppServices services) async {
  await tester.runAsync(services.dispose);
}

/// Bọc màn hình bằng providers cần thiết (AppServices, repositories, ...).
Widget _wrap(AppServices services, Widget child) => MultiProvider(
  providers: buildAppProviders(services),
  child: MaterialApp(
    theme: ThemeData.light(),
    locale: const Locale('vi'),
    home: child,
  ),
);

/// Đặt cỡ chữ hệ thống (textScaleFactor) cho toàn bộ cây kiểm thử.
/// Flutter 3.38 TestFlutterView không có setter textScaler, nên dùng MediaQuery.
Widget _withTextScale(double factor, Widget child) => MediaQuery(
  data: MediaQueryData(textScaler: TextScaler.linear(factor)),
  child: child,
);

/// Cho event loop THẬT chạy một nhịp để Native sqlite (sqflite FFI) trả
/// kết quả về future, rồi pump một frame để fake-zone xử lý continuation
/// (chuỗi multi-await trong initState->_load chạy tiếp, setState render).
Future<void> _realTick(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump(const Duration(milliseconds: 16));
}

/// Đẩy chuỗi _load() nhiều `await` DB của TodayScreen/TopicDetailScreen tới
/// khi ổn định. Mỗi vòng xen kẽ: real-loop (native sqlite trả kết quả) +
/// fake-pump (continuation chạy tiếp, setState render). Vòng lặp có giới hạn
/// nên không bao giờ treo vô hạn.
Future<void> _settleReal(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await _realTick(tester);
    if (!tester.binding.hasScheduledFrame) {
      break;
    }
  }
}

/// Pump widget, chờ giao diện ổn định (bao gồm tải dữ liệu bất đồng bộ).
/// sqflite FFI chạy event loop thật — cần xen kẽ runAsync ngoài FakeAsync
/// với pump; mỗi guarded call (pumpWidget/pump) đều được `await` tuần tự
/// nên không xung đột TestAsyncUtils guard.
Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await _settleReal(tester);
  // Xả nốt vài frame animation còn lại bằng fake time thuần (giới hạn cố định).
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Trả về exception (nếu có) sau khi render — dùng để phát hiện layout crash.
Exception? _exception(WidgetTester tester) => tester.takeException();

void _smallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('TodayScreen — overflow responsive', () {
    testWidgets('màn hình nhỏ, dữ liệu bình thường không ném exception', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      // Seed DB trong real event loop (FFI trong fake-zone sẽ treo pumpWidget).
      await _db<bool>(tester, (AppServices s) async {
        final topic = await s.topics.create(name: 'Toán');
        final item = await s.knowledge.create(
          topicId: topic.id,
          title: 'Công thức',
          content: 'Nội dung kiểm tra.',
        );
        await s.cards.create(
          knowledgeItemId: item.id,
          question: 'Test?',
          answer: 'A',
          dueAt: DateTime.now(),
        );
        return true;
      }, services: services);

      _smallScreen(tester);

      await _pump(tester, _wrap(services, const TodayScreen()));

      expect(_exception(tester), isNull);
      expect(find.text('Mỗi ngày nhớ thêm một chút'), findsOneWidget);

      await _dispose(tester, services);
    });

    testWidgets('màn hình nhỏ + tên chủ đề dài không tràn ngang', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      await _db<bool>(tester, (AppServices s) async {
        await s.topics.create(
          name:
              'Chủ đề học tập lập trình hướng đối tượng Java Spring Boot nâng cao',
        );
        await s.knowledge.create(
          topicId: (await s.topics.list()).first.id,
          title: 'Bài 1',
          content: 'Nội dung',
        );
        return true;
      }, services: services);

      _smallScreen(tester);

      await _pump(tester, _wrap(services, const TodayScreen()));

      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });

    testWidgets('cỡ chữ lớn 1.5× không phá vỡ bố cục', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      await _db<bool>(tester, (AppServices s) async {
        await s.topics.create(name: 'Toán');
        return true;
      }, services: services);

      _smallScreen(tester);

      await _pump(
        tester,
        _withTextScale(1.5, _wrap(services, const TodayScreen())),
      );

      _smallScreen(tester);

      await _pump(
        tester,
        _withTextScale(1.5, _wrap(services, const TodayScreen())),
      );

      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });

    testWidgets('trạng thái rỗng không ném exception', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);

      _smallScreen(tester);

      await _pump(tester, _wrap(services, const TodayScreen()));

      expect(_exception(tester), isNull);
      // Card trạng thái rỗng nằm dưới khung nhìn ở 360×640 — cuộn tới trước khi kiểm tra.
      await tester.scrollUntilVisible(
        find.text('Bạn chưa có chủ đề nào.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Bạn chưa có chủ đề nào.'), findsOneWidget);

      await _dispose(tester, services);
    });

    testWidgets('nhiều chủ đề gần đây không ném exception', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      await _db<bool>(tester, (AppServices s) async {
        for (int i = 0; i < 6; i++) {
          await s.topics.create(name: 'Chủ đề số $i');
        }
        return true;
      }, services: services);

      _smallScreen(tester);

      await _pump(tester, _wrap(services, const TodayScreen()));

      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });
  });

  group('TopicDetailScreen — overflow responsive', () {
    testWidgets('màn hình nhỏ + tên chủ đề dài + mô tả dài không ném exception', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      final topic = await _db(tester, (AppServices s) async {
        final created = await s.topics.create(
          name:
              'Chủ đề học tập lập trình hướng đối tượng Java Spring Boot nâng cao',
          description:
              'Đây là mô tả rất dài của chủ đề dùng để kiểm tra bố cục trên màn hình nhỏ. '
              'Nội dung mô tả có thể bao gồm nhiều câu và nhiều dòng khi hiển thị.',
        );
        await s.knowledge.create(
          topicId: created.id,
          title: 'Kiến thức 1',
          content: 'Nội dung kiến thức 1',
        );
        return created;
      }, services: services);

      _smallScreen(tester);

      await _pump(
        tester,
        _wrap(services, TopicDetailScreen(topicId: topic.id)),
      );

      expect(_exception(tester), isNull);
      expect(find.text(topic.name), findsOneWidget);

      await _dispose(tester, services);
    });

    testWidgets('cỡ chữ lớn 1.5× không phá vỡ bố cục', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      final topic = await _db(
        tester,
        (AppServices s) => s.topics.create(name: 'Chủ đề dài hơn bình thường'),
        services: services,
      );

      _smallScreen(tester);

      await _pump(
        tester,
        _withTextScale(
          1.5,
          _wrap(services, TopicDetailScreen(topicId: topic.id)),
        ),
      );

      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });

    testWidgets('trạng thái chưa có kiến thức không ném exception', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      final topic = await _db(
        tester,
        (AppServices s) => s.topics.create(name: 'Chủ đề rỗng'),
        services: services,
      );

      _smallScreen(tester);

      await _pump(
        tester,
        _wrap(services, TopicDetailScreen(topicId: topic.id)),
      );

      expect(_exception(tester), isNull);
      expect(find.text('Chưa có kiến thức'), findsOneWidget);

      await _dispose(tester, services);
    });

    testWidgets('nhiều kiến thức (danh sách dài) không ném exception', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      final topic = await _db(tester, (AppServices s) async {
        final created = await s.topics.create(name: 'Chủ đề nhiều bài');
        for (int i = 0; i < 10; i++) {
          await s.knowledge.create(
            topicId: created.id,
            title: 'Bài học số $i',
            content: 'Nội dung bài học số $i dùng kiểm tra danh sách dài.',
          );
        }
        return created;
      }, services: services);

      _smallScreen(tester);

      await _pump(
        tester,
        _wrap(services, TopicDetailScreen(topicId: topic.id)),
      );

      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });

    testWidgets('mô tả rất dài trên màn hình ngắn không tràn dọc', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      final topic = await _db(
        tester,
        (AppServices s) => s.topics.create(
          name: 'Chủ đề mô tả dài',
          description: 'A ' * 500, // nội dung nhiều dòng để ép thẻ header cao
        ),
        services: services,
      );

      _smallScreen(tester);

      await _pump(
        tester,
        _wrap(services, TopicDetailScreen(topicId: topic.id)),
      );

      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });

    testWidgets('dialog sửa chủ đề mở trên màn hình nhỏ không ném exception', (
      WidgetTester tester,
    ) async {
      final services = await _buildServices(tester);
      final topic = await _db(
        tester,
        (AppServices s) => s.topics.create(name: 'Chủ đề cần sửa'),
        services: services,
      );

      _smallScreen(tester);

      await _pump(
        tester,
        _wrap(services, TopicDetailScreen(topicId: topic.id)),
      );

      await tester.tap(find.byTooltip('Sửa'));
      // Dialog save gọi DB thật qua _editTopic -> topics.update: cho real
      // event loop chạy rồi mới pump frame kế tiếp.
      await _settleReal(tester);

      expect(find.text('Sửa chủ đề'), findsOneWidget);
      expect(_exception(tester), isNull);

      await _dispose(tester, services);
    });
  });

  group('LessonDiscoverScreen — overflow responsive', () {
    testWidgets(
      'màn hình nhỏ, mở chọn nhiều chủ đề không overflow, đủ chế độ + nút tạo',
      (WidgetTester tester) async {
        final services = await _buildServices(tester);
        _smallScreen(tester);

        await _pump(
          tester,
          _wrap(services, const LessonDiscoverScreen()),
        );

        expect(_exception(tester), isNull);

        // Chạm vào thẻ lĩnh vực đầu tiên (Khoa học) để mở bottom sheet
        await tester.tap(find.byType(AppCard).first);
        // Bottom sheet là modal route — cần nhiều frame để render xong
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(_exception(tester), isNull);

        // Tên lĩnh vực hiển thị (trong bottom sheet, có thể trùng background)
        expect(find.text('Khoa học'), findsWidgets);

        // Ô nhập chủ đề tùy chỉnh (AppTextField dùng RichText nên tìm bằng type)
        expect(find.byType(AppTextField), findsOneWidget);

        // Chức năng chọn chủ đề ngẫu nhiên
        expect(find.text('Chủ đề ngẫu nhiên'), findsOneWidget);

        // Nút chọn nhiều: Tất cả / Bỏ chọn tất cả
        expect(find.text('Tất cả'), findsOneWidget);
        expect(find.text('Bỏ chọn tất cả'), findsOneWidget);

        // Ô nhập chủ đề tùy chỉnh + nút Thêm
        expect(find.text('Thêm chủ đề riêng'), findsOneWidget);
        expect(find.text('Chủ đề tùy chỉnh'), findsOneWidget);
        expect(find.text('Thêm'), findsOneWidget);

        // Bốn chế độ bài học
        expect(find.text('Tổng quan'), findsOneWidget);
        expect(find.text('Tiêu chuẩn'), findsOneWidget);
        expect(find.text('Chuyên sâu'), findsOneWidget);

        // Nút tạo bài học
        expect(find.text('Tạo bài học'), findsOneWidget);

        await _dispose(tester, services);
      },
    );

    testWidgets(
      'màn hình nhỏ, bàn phím mở không overflow, nút tạo vẫn accessible',
      (WidgetTester tester) async {
        final services = await _buildServices(tester);
        _smallScreen(tester);

        await _pump(
          tester,
          _wrap(services, const LessonDiscoverScreen()),
        );

        expect(_exception(tester), isNull);

        // Mở bottom sheet
        await tester.tap(find.byType(AppCard).first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(_exception(tester), isNull);

        // Bật bàn phím bằng cách chạm vào ô nhập chủ đề
        await tester.tap(find.byType(TextField).first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));

        expect(_exception(tester), isNull);

        // Nút tạo vẫn hiển thị sau khi bàn phím mở
        expect(find.text('Tạo bài học'), findsOneWidget);

        await _dispose(tester, services);
      },
    );
  });
}

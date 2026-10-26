import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/db/schema.dart';
import 'package:mind_keeper/data/models/course.dart';
import 'package:mind_keeper/data/repositories/course_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

/// Migration v9 (GĐ23): chỉ THÊM bảng khóa học + đề cương.
void main() {
  setUp(initFfi);

  test('DB mới có bảng courses/course_items + index', () async {
    final AppDatabase app = await openMemoryDb();
    final List<String> names = (await app.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'",
    )).map((Map<String, Object?> r) => r['name']! as String).toList();
    expect(
      names,
      containsAll(<String>[
        'courses',
        'course_items',
        'idx_course_items_pos',
        'idx_course_items_status',
        'idx_courses_topic',
      ]),
    );
    expect(DbSchema.currentVersion, 9);
    expect(await app.db.getVersion(), 9);
    await app.close();
  });

  test('migration v8→v9 thêm bảng, dữ liệu v8 giữ nguyên, FK + UNIQUE hoạt động',
      () async {
    final Directory dir = await Directory.systemTemp.createTemp('mk_mig_v9');
    final Database raw = await databaseFactoryFfi.openDatabase(
      '${dir.path}/v8.db',
      options: OpenDatabaseOptions(
        version: 8,
        onCreate: (Database db, int version) async {
          await db.execute(DbSchema.topics);
          await db.execute(DbSchema.lessons);
          await db.execute(DbSchema.sources);
          await db.execute(DbSchema.knowledgeItems);
        },
      ),
    );
    await raw.insert('topics', <String, Object?>{
      'id': 'tp_v8',
      'name': 'Chủ đề v8',
      'created_at': 1,
      'updated_at': 1,
    });
    await raw.close();

    final AppDatabase upgraded = AppDatabase(
      factory: databaseFactoryFfi,
      name: 'v8.db',
      directory: dir.path,
    );
    await upgraded.open();
    expect(await upgraded.db.getVersion(), 9);
    expect(
      (await upgraded.db.query('topics', where: "id = 'tp_v8'")).single['name'],
      'Chủ đề v8',
    );

    final CourseRepository repo = CourseRepository(upgraded);
    final Course c = await repo.createWithOutline(
      topicId: 'tp_v8',
      name: 'Chủ đề v8',
      level: CourseLevel.pro,
      titles: <String>['A', 'B'],
    );
    expect((await repo.getById(c.id))!.level, CourseLevel.pro);
    expect(await repo.listItems(c.id), hasLength(2));

    // UNIQUE (course_id, position)
    await expectLater(
      upgraded.db.insert('course_items', <String, Object?>{
        'id': 'dup',
        'course_id': c.id,
        'position': 0,
        'title': 'trùng',
        'created_at': 1,
        'updated_at': 1,
      }),
      throwsA(isA<DatabaseException>()),
    );
    // FK: xóa chủ đề → xóa khóa học và đề cương.
    await upgraded.db.delete('topics', where: "id = 'tp_v8'");
    expect(await repo.getById(c.id), isNull);
    expect(await repo.listItems(c.id), isEmpty);
    await upgraded.close();
  });

  test('appendItem nối thêm mẩu và cập nhật total_items', () async {
    final AppDatabase app = await openMemoryDb();
    await app.db.insert('topics', <String, Object?>{
      'id': 't',
      'name': 'T',
      'created_at': 1,
      'updated_at': 1,
    });
    final CourseRepository repo = CourseRepository(app);
    final Course c = await repo.createWithOutline(
      topicId: 't',
      name: 'T',
      level: CourseLevel.basic,
      titles: <String>['A'],
    );
    final CourseItem added = await repo.appendItem(c.id, 'B');
    expect(added.position, 1);
    expect((await repo.getById(c.id))!.totalItems, 2);
    await app.close();
  });

  group('payload course', () {
    test('legacy course:<id> và JSON đều ra kindCourse', () {
      final NotificationPayload a = NotificationPayload.parse('course:ci_1');
      expect(a.type, NotificationPayload.kindCourse);
      expect(a.id, 'ci_1');
      expect(a.isCourse, isTrue);
      final NotificationPayload b = NotificationPayload.parse(
        '{"type":"course","id":"ci_2"}',
      );
      expect(b.isCourse, isTrue);
      expect(b.id, 'ci_2');
      expect(a.toLegacyString(), 'course:ci_1');
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/db/schema.dart';
import 'package:mind_keeper/data/models/course.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

/// Migration v10: chỉ THÊM cột course_items.memory_tip (mẩu cũ = rỗng).
void main() {
  setUp(initFfi);

  test('DB mới có cột memory_tip', () async {
    final AppDatabase app = await openMemoryDb();
    final List<String> cols = (await app.db.rawQuery(
      'PRAGMA table_info(course_items)',
    )).map((Map<String, Object?> r) => r['name']! as String).toList();
    expect(cols, contains('memory_tip'));
    expect(DbSchema.currentVersion, 10);
    await app.close();
  });

  test(
    'migration v9→v10 thêm cột, mẩu cũ giữ nguyên với memory_tip rỗng',
    () async {
      final Directory dir = await Directory.systemTemp.createTemp('mk_mig_v10');
      final Database raw = await databaseFactoryFfi.openDatabase(
        '${dir.path}/v9.db',
        options: OpenDatabaseOptions(
          version: 9,
          onCreate: (Database db, int version) async {
            await db.execute(DbSchema.topics);
            await db.execute(DbSchema.lessons);
            await db.execute(DbSchema.sources);
            await db.execute(DbSchema.knowledgeItems);
            await db.execute(DbSchema.courses);
            // Bảng course_items ĐỜI v9: chưa có memory_tip.
            await db.execute('''
CREATE TABLE course_items (
  id TEXT PRIMARY KEY,
  course_id TEXT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  knowledge_item_id TEXT REFERENCES knowledge_items(id) ON DELETE SET NULL,
  summary TEXT NOT NULL DEFAULT '',
  sources_note TEXT NOT NULL DEFAULT '',
  release_at INTEGER,
  read_at INTEGER,
  error TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
          },
        ),
      );
      await raw.insert('topics', <String, Object?>{
        'id': 'tp_old',
        'name': 'Chủ đề cũ',
        'created_at': 1,
        'updated_at': 1,
      });
      await raw.insert('courses', <String, Object?>{
        'id': 'co_old',
        'topic_id': 'tp_old',
        'name': 'Khóa cũ',
        'level': 'basic',
        'total_items': 1,
        'per_day': 1,
        'status': 'active',
        'created_at': 1,
        'updated_at': 1,
      });
      await raw.insert('course_items', <String, Object?>{
        'id': 'ci_old',
        'course_id': 'co_old',
        'position': 0,
        'title': 'Mẩu cũ',
        'summary': 'Tóm tắt cũ',
        'created_at': 1,
        'updated_at': 1,
      });
      await raw.close();

      final AppDatabase upgraded = AppDatabase(
        factory: databaseFactoryFfi,
        name: 'v9.db',
        directory: dir.path,
      );
      await upgraded.open();
      expect(await upgraded.db.getVersion(), DbSchema.currentVersion);
      final Map<String, Object?> row = (await upgraded.db.query(
        'course_items',
        where: "id = 'ci_old'",
      )).single;
      expect(row['title'], 'Mẩu cũ');
      expect(row['summary'], 'Tóm tắt cũ');
      expect(row['memory_tip'], '');

      // Mẩu cũ vẫn đọc được qua model, memoryTip rỗng → card Mẹo nhớ bị ẩn.
      final CourseItem item = CourseItem.fromMap(row);
      expect(item.memoryTip, isEmpty);
      await upgraded.close();
    },
  );
}

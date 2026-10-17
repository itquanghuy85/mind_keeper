import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/db/schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

void main() {
  setUp(initFfi);

  test('tạo toàn bộ bảng và chỉ mục ở phiên bản hiện tại', () async {
    final AppDatabase app = await openMemoryDb();
    final List<String> tables = (await app.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    ))
        .map((Map<String, Object?> row) => row['name']! as String)
        .toList();
    expect(
      tables,
      containsAll(<String>[
        'topics',
        'sources',
        'knowledge_items',
        'review_cards',
        'review_logs',
        'lessons',
      ]),
    );

    final List<String> indexes = (await app.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
    ))
        .map((Map<String, Object?> row) => row['name']! as String)
        .toList();
    expect(
      indexes,
      containsAll(<String>[
        'idx_cards_due',
        'idx_logs_time',
        'idx_lessons_dedup',
        'idx_lessons_domain',
      ]),
    );
    expect(await app.db.getVersion(), DbSchema.currentVersion);
    await app.close();
  });

  test('kích hoạt ràng buộc khóa ngoại', () async {
    final AppDatabase app = await openMemoryDb();
    await expectLater(
      app.db.insert('review_cards', <String, Object?>{
        'id': 'rc_x',
        'knowledge_item_id': 'khong_ton_tai',
        'question': 'Q',
        'answer': 'A',
        'due_at': 0,
        'created_at': 0,
        'updated_at': 0,
      }),
      throwsA(anything),
    );
    await app.close();
  });

  test('khóa ngoại chặn tham chiếu mồ côi tới chủ đề', () async {
    final AppDatabase app = await openMemoryDb();
    await expectLater(
      app.db.insert('knowledge_items', <String, Object?>{
        'id': 'ki_x',
        'topic_id': 'khong_co',
        'title': 't',
        'content': 'c',
        'created_at': 0,
        'updated_at': 0,
      }),
      throwsA(anything),
    );
    await app.close();
  });

  test('migration chạy theo phiên bản và giữ dữ liệu cũ', () async {
    final Directory temp = await Directory.systemTemp.createTemp('mk_migration');
    final String dbPath = '${temp.path}/legacy.db';

    final Database legacy = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
CREATE TABLE topics (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
        },
      ),
    );
    await legacy.insert('topics', <String, Object?>{
      'id': 'tp_old',
      'name': 'Chủ đề cũ',
      'created_at': 1,
      'updated_at': 1,
    });
    await legacy.close();

    final AppDatabase upgraded = AppDatabase(
      factory: databaseFactoryFfi,
      name: 'legacy.db',
      directory: temp.path,
      schemaVersion: 2,
      migrations: <SchemaMigration>[
        SchemaMigration(
          fromVersion: 1,
          toVersion: 2,
          upgrade: (DatabaseExecutor db) async {
            await db.execute(
              "ALTER TABLE topics ADD COLUMN description TEXT NOT NULL DEFAULT ''",
            );
            await db.execute(
              "ALTER TABLE topics ADD COLUMN category TEXT NOT NULL DEFAULT ''",
            );
            await db.execute(
              "ALTER TABLE topics ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1",
            );
          },
        ),
      ],
    );
    await upgraded.open();
    expect(await upgraded.db.getVersion(), 2);

    final List<Map<String, Object?>> rows =
        await upgraded.db.query('topics', where: 'id = ?', whereArgs: <Object?>['tp_old']);
    expect(rows, hasLength(1));
    expect(rows.first['name'], 'Chủ đề cũ');
    expect(rows.first['description'], '');
    expect(rows.first['is_active'], 1);

    await upgraded.close();
    await temp.delete(recursive: true);
  });

  test('thiếu migration thì báo lỗi thay vì im lặng bỏ qua', () async {
    final Directory temp = await Directory.systemTemp.createTemp('mk_migration_missing');
    final String dbPath = '${temp.path}/v1.db';

    final Database legacy = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE topics (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
        },
      ),
    );
    await legacy.close();

    final AppDatabase broken = AppDatabase(
      factory: databaseFactoryFfi,
      name: 'v1.db',
      directory: temp.path,
      schemaVersion: 3,
      migrations: <SchemaMigration>[
        SchemaMigration(
          fromVersion: 1,
          toVersion: 2,
          upgrade: (DatabaseExecutor db) async {
            await db.execute("ALTER TABLE topics ADD COLUMN x TEXT");
          },
        ),
      ],
    );

    await expectLater(broken.open(), throwsA(isA<StateError>()));
    await temp.delete(recursive: true);
  });

  test('DbSchema sinh câu lệnh SQL hợp lệ', () {
    expect(DbSchema.tables, hasLength(6));
    expect(DbSchema.indexes, isNotEmpty);
    int withReferences = 0;
    for (final String sql in DbSchema.tables) {
      expect(sql.trimLeft(), startsWith('CREATE TABLE'));
      if (sql.contains('REFERENCES')) withReferences += 1;
    }
    // 5 bảng con có khóa ngoại (gồm lessons.linked_topic_id); topics không có.
    expect(withReferences, 5);
  });

  test('migration 1→2 tạo bảng lessons và giữ dữ liệu cũ', () async {
    final Directory temp = await Directory.systemTemp.createTemp('mk_migration_v2');
    final String dbPath = '${temp.path}/v1_full.db';

    final Database legacy = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
CREATE TABLE topics (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT '',
  icon TEXT NOT NULL DEFAULT '',
  origin TEXT NOT NULL DEFAULT 'personal',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
          await db.execute('''
CREATE TABLE knowledge_items (
  id TEXT PRIMARY KEY,
  topic_id TEXT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  source_id TEXT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  details TEXT NOT NULL DEFAULT '',
  origin TEXT NOT NULL DEFAULT 'user_confirmed',
  is_favorite INTEGER NOT NULL DEFAULT 0,
  is_paused INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
        },
      ),
    );
    await legacy.insert('topics', <String, Object?>{
      'id': 'tp_old',
      'name': 'Chủ đề cũ',
      'created_at': 1,
      'updated_at': 1,
    });
    await legacy.insert('knowledge_items', <String, Object?>{
      'id': 'ki_old',
      'topic_id': 'tp_old',
      'title': 'Mục cũ',
      'content': 'Nội dung cũ',
      'created_at': 1,
      'updated_at': 1,
    });
    await legacy.close();

    final AppDatabase upgraded = AppDatabase(
      factory: databaseFactoryFfi,
      name: 'v1_full.db',
      directory: temp.path,
    );
    await upgraded.open();
    expect(await upgraded.db.getVersion(), DbSchema.currentVersion);

    final List<Map<String, Object?>> topics =
        await upgraded.db.query('topics', where: 'id = ?', whereArgs: <Object?>['tp_old']);
    expect(topics, hasLength(1));
    expect(topics.first['name'], 'Chủ đề cũ');
    final List<Map<String, Object?>> items =
        await upgraded.db.query('knowledge_items', where: 'id = ?', whereArgs: <Object?>['ki_old']);
    expect(items, hasLength(1));
    expect(items.first['title'], 'Mục cũ');

    // Bảng lessons đã sẵn sàng cho dữ liệu mới, khóa unique dedup hoạt động.
    await upgraded.db.insert('lessons', <String, Object?>{
      'id': 'ls_1',
      'domain_id': 'science',
      'domain_name': 'Khoa học',
      'topic': 'Ánh sáng',
      'mode': 'standard',
      'prompt_version': 'v1',
      'dedup_key': 'dedup-1',
      'title': 'Bài học ánh sáng',
      'content_json': '{}',
      'created_at': 1,
      'updated_at': 1,
    });
    await expectLater(
      upgraded.db.insert('lessons', <String, Object?>{
        'id': 'ls_2',
        'domain_id': 'science',
        'domain_name': 'Khoa học',
        'topic': 'Ánh sáng',
        'mode': 'standard',
        'prompt_version': 'v1',
        'dedup_key': 'dedup-1',
        'title': 'Bài trùng',
        'content_json': '{}',
        'created_at': 1,
        'updated_at': 1,
      }),
      throwsA(anything),
    );

    await upgraded.close();
    await temp.delete(recursive: true);
  });
}

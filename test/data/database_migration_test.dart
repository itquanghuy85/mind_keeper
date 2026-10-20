import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/db/schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

void main() {
  setUp(initFfi);

  test('táº¡o toÃ n bá»™ báº£ng vÃ  chá»‰ má»¥c á»Ÿ phiÃªn báº£n hiá»‡n táº¡i', () async {
    final AppDatabase app = await openMemoryDb();
    final List<String> tables = (await app.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    )).map((Map<String, Object?> row) => row['name']! as String).toList();
    expect(
      tables,
      containsAll(<String>[
        'topics',
        'sources',
        'knowledge_items',
        'review_cards',
        'review_logs',
        'lessons',
        'knowledge_generation_tasks',
      ]),
    );

    final List<String> indexes = (await app.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'",
    )).map((Map<String, Object?> row) => row['name']! as String).toList();
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

  test('kÃ­ch hoáº¡t rÃ ng buá»™c khÃ³a ngoáº¡i', () async {
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

  test('khÃ³a ngoáº¡i cháº·n tham chiáº¿u má»“ cÃ´i tá»›i chá»§ Ä‘á»', () async {
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

  test('migration cháº¡y theo phiÃªn báº£n vÃ  giá»¯ dá»¯ liá»‡u cÅ©', () async {
    final Directory temp = await Directory.systemTemp.createTemp(
      'mk_migration',
    );
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
      'name': 'Chá»§ Ä‘á» cÅ©',
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

    final List<Map<String, Object?>> rows = await upgraded.db.query(
      'topics',
      where: 'id = ?',
      whereArgs: <Object?>['tp_old'],
    );
    expect(rows, hasLength(1));
    expect(rows.first['name'], 'Chá»§ Ä‘á» cÅ©');
    expect(rows.first['description'], '');
    expect(rows.first['is_active'], 1);

    await upgraded.close();
    await temp.delete(recursive: true);
  });

  test('thiáº¿u migration thÃ¬ bÃ¡o lá»—i thay vÃ¬ im láº·ng bá» qua', () async {
    final Directory temp = await Directory.systemTemp.createTemp(
      'mk_migration_missing',
    );
    final String dbPath = '${temp.path}/v1.db';

    final Database legacy = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
            'CREATE TABLE topics (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
          );
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

  test('DbSchema sinh cÃ¢u lá»‡nh SQL há»£p lá»‡', () {
    expect(DbSchema.tables, hasLength(8));
    expect(DbSchema.indexes, isNotEmpty);
    int withReferences = 0;
    for (final String sql in DbSchema.tables) {
      if (sql.contains('REFERENCES')) withReferences += 1;
    }
    expect(withReferences, 7);
  });

  test('migration 1â†’2 táº¡o báº£ng lessons vÃ  giá»¯ dá»¯ liá»‡u cÅ©', () async {
    final Directory temp = await Directory.systemTemp.createTemp(
      'mk_migration_v2',
    );
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
      'name': 'Chá»§ Ä‘á» cÅ©',
      'created_at': 1,
      'updated_at': 1,
    });
    await legacy.insert('knowledge_items', <String, Object?>{
      'id': 'ki_old',
      'topic_id': 'tp_old',
      'title': 'Má»¥c cÅ©',
      'content': 'Ná»™i dung cÅ©',
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

    final List<Map<String, Object?>> topics = await upgraded.db.query(
      'topics',
      where: 'id = ?',
      whereArgs: <Object?>['tp_old'],
    );
    expect(topics, hasLength(1));
    expect(topics.first['name'], 'Chá»§ Ä‘á» cÅ©');
    final List<Map<String, Object?>> items = await upgraded.db.query(
      'knowledge_items',
      where: 'id = ?',
      whereArgs: <Object?>['ki_old'],
    );
    expect(items, hasLength(1));
    expect(items.first['title'], 'Má»¥c cÅ©');

    // Báº£ng lessons Ä‘Ã£ sáºµn sÃ ng cho dá»¯ liá»‡u má»›i, khÃ³a unique dedup hoáº¡t Ä‘á»™ng.
    await upgraded.db.insert('lessons', <String, Object?>{
      'id': 'ls_1',
      'domain_id': 'science',
      'domain_name': 'Khoa há»c',
      'topic': 'Ãnh sÃ¡ng',
      'mode': 'standard',
      'prompt_version': 'v1',
      'dedup_key': 'dedup-1',
      'title': 'BÃ i há»c Ã¡nh sÃ¡ng',
      'content_json': '{}',
      'created_at': 1,
      'updated_at': 1,
    });
    await expectLater(
      upgraded.db.insert('lessons', <String, Object?>{
        'id': 'ls_2',
        'domain_id': 'science',
        'domain_name': 'Khoa há»c',
        'topic': 'Ãnh sÃ¡ng',
        'mode': 'standard',
        'prompt_version': 'v1',
        'dedup_key': 'dedup-1',
        'title': 'BÃ i trÃ¹ng',
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

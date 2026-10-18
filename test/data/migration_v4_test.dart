import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/db/schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

void main() {
  setUp(initFfi);

  test('migration v3->v4 adds started_at column to knowledge_items', () async {
    final Directory temp = await Directory.systemTemp.createTemp(
      'mk_migration_v4',
    );
    final String dbPath = '${temp.path}/v3.db';

    // Create v3 database
    final Database legacy = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
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
          await db.execute('''
CREATE TABLE review_cards (
  id TEXT PRIMARY KEY,
  knowledge_item_id TEXT NOT NULL REFERENCES knowledge_items(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  question_type TEXT NOT NULL DEFAULT 'recall',
  fsrs_state INTEGER NOT NULL DEFAULT 0,
  fsrs_step INTEGER,
  stability REAL,
  difficulty REAL,
  due_at INTEGER NOT NULL,
  last_review_at INTEGER,
  reps INTEGER NOT NULL DEFAULT 0,
  lapses INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
          await db.execute('''
CREATE TABLE review_logs (
  id TEXT PRIMARY KEY,
  card_id TEXT NOT NULL REFERENCES review_cards(id) ON DELETE CASCADE,
  reviewed_at INTEGER NOT NULL,
  rating INTEGER NOT NULL,
  due_before INTEGER,
  due_after INTEGER,
  state_before INTEGER,
  state_after INTEGER,
  stability_before REAL,
  stability_after REAL,
  answer_text TEXT,
  auto_grade TEXT,
  note TEXT
)''');
          await db.execute('''
CREATE TABLE lessons (
  id TEXT PRIMARY KEY,
  domain_id TEXT NOT NULL,
  domain_name TEXT NOT NULL,
  topic TEXT NOT NULL,
  mode TEXT NOT NULL DEFAULT 'standard',
  prompt_version TEXT NOT NULL DEFAULT 'v1',
  dedup_key TEXT NOT NULL,
  title TEXT NOT NULL,
  content_json TEXT NOT NULL,
  questions_json TEXT NOT NULL DEFAULT '[]',
  sources_json TEXT NOT NULL DEFAULT '[]',
  verification TEXT NOT NULL DEFAULT 'unverified',
  medical INTEGER NOT NULL DEFAULT 0,
  word_count INTEGER NOT NULL DEFAULT 0,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  is_read INTEGER NOT NULL DEFAULT 0,
  linked_topic_id TEXT REFERENCES topics(id) ON DELETE SET NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
          await db.execute('''
CREATE TABLE knowledge_generation_tasks (
  topic_id TEXT PRIMARY KEY REFERENCES topics(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending',
  total_planned INTEGER NOT NULL DEFAULT 0,
  completed_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0,
  current_batch INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  started_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  completed_at INTEGER
)''');
        },
      ),
    );

    // Insert test data
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

    // Open with current version (4) - should run migration
    final AppDatabase upgraded = AppDatabase(
      factory: databaseFactoryFfi,
      name: 'v3.db',
      directory: temp.path,
    );
    await upgraded.open();
    expect(await upgraded.db.getVersion(), DbSchema.currentVersion);

    // Check started_at column exists
    final List<Map<String, Object?>> columns = await upgraded.db.rawQuery(
      "PRAGMA table_info(knowledge_items)",
    );
    final bool hasStartedAt = columns.any(
      (Map<String, Object?> c) => c['name'] == 'started_at',
    );
    expect(hasStartedAt, isTrue, reason: 'started_at column should exist after migration');

    // Check data preserved
    final List<Map<String, Object?>> items = await upgraded.db.query(
      'knowledge_items',
      where: 'id = ?',
      whereArgs: <Object>['ki_old'],
    );
    expect(items, hasLength(1));
    expect(items.first['title'], 'Mục cũ');
    // startedAt should be null for old data
    expect(items.first['started_at'], isNull);

    // New inserts should work with started_at
    await upgraded.db.insert('knowledge_items', <String, Object?>{
      'id': 'ki_new',
      'topic_id': 'tp_old',
      'title': 'Mục mới',
      'content': 'Nội dung mới',
      'started_at': 12345,
      'created_at': 1,
      'updated_at': 1,
    });
    final List<Map<String, Object?>> newItem = await upgraded.db.query(
      'knowledge_items',
      where: 'id = ?',
      whereArgs: <Object>['ki_new'],
    );
    expect(newItem.first['started_at'], 12345);

    await upgraded.close();
    await temp.delete(recursive: true);
  });

  test('migration v1->v4 runs all intermediate migrations and keeps data', () async {
    final Directory temp = await Directory.systemTemp.createTemp(
      'mk_migration_v1_to_v4',
    );
    final String dbPath = '${temp.path}/v1.db';

    // Create v1 database (minimal schema)
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

    // Insert test data
    await legacy.insert('topics', <String, Object?>{
      'id': 'tp_v1',
      'name': 'Chủ đề v1',
      'created_at': 1,
      'updated_at': 1,
    });
    await legacy.insert('knowledge_items', <String, Object?>{
      'id': 'ki_v1',
      'topic_id': 'tp_v1',
      'title': 'Mục v1',
      'content': 'Nội dung v1',
      'created_at': 1,
      'updated_at': 1,
    });
    await legacy.close();

    // Open with current version (4) - should run all migrations
    final AppDatabase upgraded = AppDatabase(
      factory: databaseFactoryFfi,
      name: 'v1.db',
      directory: temp.path,
    );
    await upgraded.open();
    expect(await upgraded.db.getVersion(), DbSchema.currentVersion);

    // Check all tables exist
    final List<Map<String, Object?>> tables = await upgraded.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    );
    final List<String> tableNames = tables
        .map((Map<String, Object?> row) => row['name']! as String)
        .toList();
    expect(
      tableNames,
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

    // Check started_at column exists
    final List<Map<String, Object?>> columns = await upgraded.db.rawQuery(
      "PRAGMA table_info(knowledge_items)",
    );
    final bool hasStartedAt = columns.any(
      (Map<String, Object?> c) => c['name'] == 'started_at',
    );
    expect(hasStartedAt, isTrue);

    // Check data preserved
    final List<Map<String, Object?>> items = await upgraded.db.query(
      'knowledge_items',
      where: 'id = ?',
      whereArgs: <Object>['ki_v1'],
    );
    expect(items, hasLength(1));
    expect(items.first['title'], 'Mục v1');

    await upgraded.close();
    await temp.delete(recursive: true);
  });
}
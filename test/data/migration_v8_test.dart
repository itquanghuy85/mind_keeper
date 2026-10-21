import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/db/schema.dart';
import 'package:mind_keeper/data/models/study_feed_item.dart';
import 'package:mind_keeper/data/repositories/study_feed_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

/// Migration v8 (GĐ17): chỉ THÊM bảng hàng đợi kế hoạch học — không ALTER/
/// DROP bảng cũ, không sửa migration đã phát hành.
void main() {
  setUp(initFfi);

  test('DB mới có bảng study_feed_items + index chống trùng, đúng phiên bản', () async {
    final AppDatabase app = await openMemoryDb();
    final List<String> tables = (await app.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    ))
        .map((Map<String, Object?> row) => row['name']! as String)
        .toList();
    expect(tables, contains('study_feed_items'));

    final List<String> indexes = (await app.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_feed%'",
    ))
        .map((Map<String, Object?> row) => row['name']! as String)
        .toList();
    expect(
      indexes,
      containsAll(<String>[
        'idx_feed_dedup',
        'idx_feed_slot',
        'idx_feed_day',
        'idx_feed_status',
      ]),
    );
    expect(await app.db.getVersion(), DbSchema.currentVersion);
    await app.close();
  });

  test('migration v7→v8 thêm bảng feed, dữ liệu v7 giữ nguyên', () async {
    final Directory dir = await Directory.systemTemp.createTemp('mk_migration_v8');
    final String dbPath = '${dir.path}/v7.db';

    // DB v7 thủ công: topics + lessons có dữ liệu, CHƯA có study_feed_items.
    final Database raw = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: (Database db, int version) async {
          await db.execute(DbSchema.topics);
          await db.execute(DbSchema.lessons);
        },
      ),
    );
    await raw.insert('topics', <String, Object?>{
      'id': 'tp_v7',
      'name': 'Chủ đề còn sót từ v7',
      'created_at': 1,
      'updated_at': 1,
    });
    await raw.insert('lessons', <String, Object?>{
      'id': 'ls_v7',
      'domain_id': 'science',
      'domain_name': 'Khoa học',
      'topic': 'Ánh sáng',
      'mode': 'standard',
      'prompt_version': 'v1',
      'dedup_key': 'dedup_v7',
      'title': 'Bài học v7',
      'content_json': '{}',
      'created_at': 1,
      'updated_at': 1,
    });
    // Bảng feed phải CHƯA tồn tại ở v7.
    final List<Map<String, Object?>> before = await raw.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'study_feed_items'",
    );
    expect(before, isEmpty);
    await raw.close();

    // Mở lại bằng AppDatabase → chạy migration 7→8.
    final AppDatabase upgraded = AppDatabase(
      factory: databaseFactoryFfi,
      name: 'v7.db',
      directory: dir.path,
    );
    await upgraded.open();
    expect(await upgraded.db.getVersion(), DbSchema.currentVersion);

    // Dữ liệu v7 còn nguyên.
    final List<Map<String, Object?>> topics = await upgraded.db.query(
      'topics',
      where: 'id = ?',
      whereArgs: <Object?>['tp_v7'],
    );
    expect(topics, hasLength(1));
    expect(topics.first['name'], 'Chủ đề còn sót từ v7');
    final List<Map<String, Object?>> lessons = await upgraded.db.query(
      'lessons',
      where: 'id = ?',
      whereArgs: <Object?>['ls_v7'],
    );
    expect(lessons, hasLength(1));
    expect(lessons.first['title'], 'Bài học v7');

    // Bảng feed hoạt động + UNIQUE chống trùng.
    final StudyFeedRepository repo = StudyFeedRepository(upgraded);
    final StudyFeedItem row = StudyFeedItem(
      id: 'sf_v8',
      kind: StudyFeedKind.quick,
      topicId: 'tp_v7',
      topicName: 'Chủ đề còn sót từ v7',
      dayKey: '2026-10-20',
      slotIndex: 0,
      status: StudyFeedStatus.queued,
      dedupKey: 'quick|2026-10-20|0',
      createdAt: DateTime.utc(2026, 10, 20),
      updatedAt: DateTime.utc(2026, 10, 20),
    );
    expect(await repo.insert(row), isTrue);
    // Trùng dedup_key (khác ngày/khung giờ) → false.
    expect(
      await repo.insert(
        StudyFeedItem(
          id: 'sf_dup',
          kind: StudyFeedKind.quick,
          topicId: 'tp_v7',
          topicName: 'Bản trùng khóa',
          dayKey: '2026-10-22',
          slotIndex: 0,
          status: StudyFeedStatus.queued,
          dedupKey: 'quick|2026-10-20|0',
          createdAt: DateTime.utc(2026, 10, 20),
          updatedAt: DateTime.utc(2026, 10, 20),
        ),
      ),
      isFalse,
    );
    // FK topic_id còn hiệu lực (tp_v7 tồn tại) — insert với topic không có
    // phải bị chặn.
    expect(
      await repo.insert(
        StudyFeedItem(
          id: 'sf_fk',
          kind: StudyFeedKind.quick,
          topicId: 'khong_ton_tai',
          topicName: 'FK sai',
          dayKey: '2026-10-21',
          slotIndex: 0,
          status: StudyFeedStatus.queued,
          dedupKey: 'quick|2026-10-21|0',
          createdAt: DateTime.utc(2026, 10, 20),
          updatedAt: DateTime.utc(2026, 10, 20),
        ),
      ),
      isFalse,
    );

    await upgraded.close();
    await dir.delete(recursive: true);
  });
}
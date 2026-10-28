import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/core/services/app_services.dart';
import 'package:mind_keeper/core/services/backup_service.dart';
import 'package:mind_keeper/core/services/notification_service.dart';
import 'package:mind_keeper/data/db/schema.dart';
import 'package:mind_keeper/data/models/knowledge_item.dart';
import 'package:mind_keeper/data/models/review_card.dart';
import 'package:mind_keeper/data/models/topic.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

Future<
  ({AppServices services, FakeNotificationService fake, BackupService backup})
>
_build() async {
  await initFfi();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final FakeNotificationService fake = FakeNotificationService();
  final AppServices services = AppServices.build(
    database: await openMemoryDb(),
    prefs: prefs,
    notifications: fake,
  );
  final BackupService backup = BackupService(
    database: services.database,
    prefs: services.prefs,
    notifications: fake,
    clock: () => DateTime.utc(2026, 10, 28, 10, 30),
  );
  return (services: services, fake: fake, backup: backup);
}

/// Dựng bộ dữ liệu mẫu đủ cả bảng cha/con, trả về id thẻ.
Future<String> _seed(AppServices s) async {
  final Topic topic = await s.topics.create(name: 'Sinh học');
  final KnowledgeItem item = await s.knowledge.create(
    topicId: topic.id,
    title: 'Ti thể',
    content: 'Ti thể là nhà máy năng lượng của tế bào.',
  );
  final ReviewCard card = await s.cards.create(
    knowledgeItemId: item.id,
    question: 'Ti thể làm gì?',
    answer: 'Tạo năng lượng.',
    dueAt: DateTime.utc(2026, 11, 2, 8),
  );
  final int due = DateTime.utc(2026, 11, 2, 8).millisecondsSinceEpoch;
  await s.database.db.update(
    'review_cards',
    <String, Object?>{
      'fsrs_state': 2,
      'stability': 3.5,
      'difficulty': 5.25,
      'reps': 4,
      'lapses': 1,
      'due_at': due,
      'last_review_at': due - 86400000,
    },
    where: 'id = ?',
    whereArgs: <Object>[card.id],
  );
  await s.database.db.insert('review_logs', <String, Object?>{
    'id': 'rl_1',
    'card_id': card.id,
    'reviewed_at': due - 86400000,
    'rating': 3,
    'due_before': due - 86400000,
    'due_after': due,
  });
  await s.database.db.insert('sources', <String, Object?>{
    'id': 'src_1',
    'topic_id': topic.id,
    'type': 'pdf',
    'title': 'Tài liệu',
    'storage_path': '/data/user/0/old.app/files/doc.pdf',
    'content_text': 'nội dung',
    'created_at': 1,
    'updated_at': 1,
  });
  await s.database.db.insert('courses', <String, Object?>{
    'id': 'co_1',
    'topic_id': topic.id,
    'name': 'Khóa A',
    'level': 'pro',
    'total_items': 1,
    'per_day': 1,
    'created_at': 1,
    'updated_at': 1,
  });
  await s.database.db.insert('course_items', <String, Object?>{
    'id': 'ci_1',
    'course_id': 'co_1',
    'position': 0,
    'title': 'Mẩu 1',
    'memory_tip': 'Mẹo nhớ mẫu',
    'created_at': 1,
    'updated_at': 1,
  });
  return card.id;
}

Future<Map<String, int>> _counts(AppServices s) async => <String, int>{
  for (final String t in BackupService.tableOrder)
    t:
        (await s.database.db.rawQuery(
              'SELECT COUNT(*) AS n FROM $t',
            )).first['n']!
            as int,
};

void main() {
  late Directory safetyDir;
  setUp(() async {
    safetyDir = await Directory.systemTemp.createTemp('mk_backup_safety');
  });

  test(
    'xuất → xóa sạch → khôi phục: số lượng, lịch FSRS và prefs khớp',
    () async {
      final r = await _build();
      final String cardId = await _seed(r.services);
      await r.services.prefs.setDailyGoal(33);
      await r.services.prefs.setLessonDefaultMode('deep');
      await r.services.prefs.setFavoriteCategories(<String>['Khoa học']);
      await r.services.prefs.setDefaultCourseLevel('master');
      await r.services.prefs.setOnboardingCompleted(true);
      final Map<String, int> before = await _counts(r.services);
      final String json = await r.backup.exportJson();

      // Xóa sạch DB + prefs.
      for (final String t in BackupService.tableOrder.reversed) {
        await r.services.database.db.delete(t);
      }
      await r.services.prefs.setDailyGoal(1);
      await r.services.prefs.setDefaultCourseLevel('basic');
      expect(
        (await _counts(r.services)).values.every((int n) => n == 0),
        isTrue,
      );

      final BackupPreview preview = r.backup.parse(json);
      final RestoreResult result = await r.backup.restore(
        preview,
        safetyDir: safetyDir,
      );

      expect(await _counts(r.services), before);
      expect(result.counts, before);
      final Map<String, Object?> card = (await r.services.database.db.query(
        'review_cards',
        where: 'id = ?',
        whereArgs: <Object>[cardId],
      )).single;
      expect(
        card['due_at'],
        DateTime.utc(2026, 11, 2, 8).millisecondsSinceEpoch,
      );
      expect(card['stability'], 3.5);
      expect(card['difficulty'], 5.25);
      expect(card['fsrs_state'], 2);
      expect(card['reps'], 4);
      expect(card['lapses'], 1);
      expect(
        (await r.services.database.db.query(
          'course_items',
        )).single['memory_tip'],
        'Mẹo nhớ mẫu',
      );
      expect(r.services.prefs.dailyGoal, 33);
      expect(r.services.prefs.lessonDefaultMode, 'deep');
      expect(r.services.prefs.favoriteCategories, <String>['Khoa học']);
      expect(r.services.prefs.defaultCourseLevel, 'master');
      expect(r.services.prefs.onboardingCompleted, isTrue);
      expect(r.fake.calls, contains('cancelAll'));
    },
  );

  test(
    'file sao lưu không chứa API key, session, ID thông báo; có header đủ',
    () async {
      final r = await _build();
      await _seed(r.services);
      await r.services.prefs.setAiConfig(
        baseUrl: 'https://example.test/v1',
        apiKey: 'sk-SECRET-123',
        model: 'm',
      );
      await r.services.prefs.setKnowledgeReminderScheduledIds(<int>[700000]);
      final String json = await r.backup.exportJson();

      expect(json, isNot(contains('sk-SECRET-123')));
      expect(json, isNot(contains('ai_api_key')));
      expect(json, isNot(contains('ai_base_url')));
      expect(json, isNot(contains('knowledge_reminder_scheduled_ids')));
      expect(json, isNot(contains('session_card_ids')));

      final Map<String, Object?> doc = jsonDecode(json) as Map<String, Object?>;
      final Map<String, Object?> header =
          doc['header']! as Map<String, Object?>;
      expect(header['format'], 'mindkeeper-backup');
      expect(header['version'], 1);
      expect(header['schemaVersion'], DbSchema.currentVersion);
      expect(header['exportedAt'], '2026-10-28T10:30:00.000Z');
      expect(header['appVersion'], isNotEmpty);
      final Map<String, Object?> counts =
          header['counts']! as Map<String, Object?>;
      expect(counts.keys, containsAll(BackupService.tableOrder));
      expect(counts['topics'], 1);
      expect(
        r.backup.suggestedFileName(),
        'mindkeeper-20261028-103000.mkbackup',
      );
    },
  );

  group('từ chối file sai', () {
    late BackupService backup;
    late String good;
    setUp(() async {
      final r = await _build();
      await _seed(r.services);
      backup = r.backup;
      good = await r.backup.exportJson();
    });

    void expectRejected(String raw, Pattern message) {
      expect(
        () => backup.parse(raw),
        throwsA(
          isA<BackupException>().having(
            (BackupException e) => e.message,
            'message',
            contains(message),
          ),
        ),
      );
    }

    test('không phải JSON', () => expectRejected('xin chào', 'không đọc được'));

    test('JSON nhưng không phải bản sao lưu', () {
      expectRejected('{"a":1}', 'header');
      expectRejected(
        '{"header":{"format":"khac"},"tables":{}}',
        'không phải bản sao lưu',
      );
      expectRejected('[1,2]', 'định dạng');
    });

    test('schema mới hơn ứng dụng', () {
      final Map<String, Object?> doc = jsonDecode(good) as Map<String, Object?>;
      (doc['header']! as Map<String, Object?>)['schemaVersion'] =
          DbSchema.currentVersion + 1;
      expectRejected(jsonEncode(doc), 'mới hơn');
    });

    test('định dạng file mới hơn', () {
      final Map<String, Object?> doc = jsonDecode(good) as Map<String, Object?>;
      (doc['header']! as Map<String, Object?>)['version'] = 99;
      expectRejected(jsonEncode(doc), 'định dạng mới hơn');
    });

    test('số dòng không khớp counts (file bị cắt)', () {
      final Map<String, Object?> doc = jsonDecode(good) as Map<String, Object?>;
      ((doc['tables']! as Map<String, Object?>)['topics']! as List<Object?>)
          .clear();
      expectRejected(jsonEncode(doc), 'thiếu hoặc hỏng');
    });
  });

  test('tạo bản sao lưu an toàn TRƯỚC khi ghi đè (chứa dữ liệu cũ)', () async {
    final r = await _build();
    await _seed(r.services);
    final String json = await r.backup.exportJson();
    await r.services.topics.create(name: 'Chủ đề chỉ có ở máy hiện tại');

    final RestoreResult result = await r.backup.restore(
      r.backup.parse(json),
      safetyDir: safetyDir,
    );
    final File safety = File(result.safetyBackupPath);
    expect(safety.existsSync(), isTrue);
    expect(result.safetyBackupPath, endsWith('.mkbackup'));
    final String text = await safety.readAsString();
    expect(text, contains('Chủ đề chỉ có ở máy hiện tại'));
    // Sau restore chủ đề phụ biến mất, dữ liệu file có mặt.
    final List<Map<String, Object?>> names = await r.services.database.db.query(
      'topics',
      columns: <String>['name'],
    );
    expect(names.map((Map<String, Object?> m) => m['name']), <String>[
      'Sinh học',
    ]);
  });

  test('lỗi giữa chừng → rollback, dữ liệu cũ nguyên vẹn', () async {
    final r = await _build();
    await _seed(r.services);
    final String json = await r.backup.exportJson();
    // Hai dòng topics trùng khóa chính → INSERT lỗi giữa transaction.
    final Map<String, Object?> doc = jsonDecode(json) as Map<String, Object?>;
    final List<Object?> topics =
        (doc['tables']! as Map<String, Object?>)['topics']! as List<Object?>;
    topics.add(topics.first);
    (doc['header']! as Map<String, Object?>)['counts'] = <String, Object?>{
      for (final String t in BackupService.tableOrder)
        t: ((doc['tables']! as Map<String, Object?>)[t]! as List<Object?>)
            .length,
    };
    final Map<String, int> before = await _counts(r.services);

    await expectLater(
      r.backup.restore(r.backup.parse(jsonEncode(doc)), safetyDir: safetyDir),
      throwsA(
        isA<BackupException>().having(
          (BackupException e) => e.message,
          'message',
          contains('giữ nguyên'),
        ),
      ),
    );
    expect(await _counts(r.services), before);
  });

  test('storage_path tuyệt đối bị xóa khi khôi phục', () async {
    final r = await _build();
    await _seed(r.services);
    final BackupPreview preview = r.backup.parse(await r.backup.exportJson());
    await r.backup.restore(preview, safetyDir: safetyDir);
    expect(
      (await r.services.database.db.query('sources')).single['storage_path'],
      isNull,
    );
  });

  test(
    'thiếu quyền thông báo → tắt cờ nhắc, hủy lịch cũ, vẫn lập lại lịch',
    () async {
      final r = await _build();
      await _seed(r.services);
      await r.services.prefs.setNotificationsEnabled(true);
      await r.services.prefs.setKnowledgeReminderEnabled(true);
      final String json = await r.backup.exportJson();
      r.fake.notificationsEnabledStatus = false;
      bool rescheduled = false;

      final RestoreResult result = await r.backup.restore(
        r.backup.parse(json),
        safetyDir: safetyDir,
        rescheduleAll: () async => rescheduled = true,
      );

      expect(result.notificationsDisabled, isTrue);
      expect(r.services.prefs.notificationsEnabled, isFalse);
      expect(r.services.prefs.knowledgeReminderEnabled, isFalse);
      expect(r.services.prefs.studyPlanNewContentNotifications, isFalse);
      expect(r.fake.calls, contains('cancelAll'));
      expect(rescheduled, isTrue);
    },
  );

  test('có quyền thông báo → giữ nguyên cờ và báo không bị tắt', () async {
    final r = await _build();
    await _seed(r.services);
    await r.services.prefs.setNotificationsEnabled(true);
    final String json = await r.backup.exportJson();
    final RestoreResult result = await r.backup.restore(
      r.backup.parse(json),
      safetyDir: safetyDir,
    );
    expect(result.notificationsDisabled, isFalse);
    expect(r.services.prefs.notificationsEnabled, isTrue);
  });
}

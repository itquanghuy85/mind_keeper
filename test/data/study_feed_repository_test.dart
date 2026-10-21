import 'package:flutter_test/flutter_test.dart';
import 'package:mind_keeper/data/db/app_database.dart';
import 'package:mind_keeper/data/models/study_feed_item.dart';
import 'package:mind_keeper/data/repositories/study_feed_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

void main() {
  setUp(initFfi);

  Future<AppDatabase> openDb() async {
    final AppDatabase app = AppDatabase(
      factory: databaseFactoryFfi,
      name: inMemoryDatabasePath,
    );
    await app.open();
    return app;
  }

  StudyFeedRepository repo(AppDatabase app) => StudyFeedRepository(app);

  StudyFeedItem makeItem({
    required String id,
    required StudyFeedKind kind,
    required String dayKey,
    required int slotIndex,
    StudyFeedStatus status = StudyFeedStatus.queued,
    String? refId,
    String? dedupKey,
  }) =>
      StudyFeedItem(
        id: id,
        kind: kind,
        topicId: null,
        topicName: 'Chủ đề $id',
        dayKey: dayKey,
        slotIndex: slotIndex,
        status: status,
        refId: refId,
        dedupKey: dedupKey ?? 'dk_$id',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  group('StudyFeedRepository — CRUD', () {
    test('insert sau getById trả đúng toàn bộ trường', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        final StudyFeedItem item = makeItem(
          id: 'sf_1',
          kind: StudyFeedKind.lesson,
          dayKey: '2026-10-20',
          slotIndex: 0,
          status: StudyFeedStatus.ready,
          refId: 'ls_abc',
          dedupKey: 'science|deep|standard|v2',
        );
        expect(await r.insert(item), isTrue);
        final StudyFeedItem? got = await r.getById('sf_1');
        expect(got, isNotNull);
        expect(got!.id, 'sf_1');
        expect(got.kind, StudyFeedKind.lesson);
        expect(got.dayKey, '2026-10-20');
        expect(got.slotIndex, 0);
        expect(got.status, StudyFeedStatus.ready);
        expect(got.refId, 'ls_abc');
        expect(got.dedupKey, 'science|deep|standard|v2');
      } finally {
        await app.close();
      }
    });

    test('getById không tìm thấy trả null', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        expect(await r.getById('khong_co'), isNull);
      } finally {
        await app.close();
      }
    });

    test('update thay đổi status và updatedAt', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        final StudyFeedItem item = makeItem(
          id: 'sf_upd',
          kind: StudyFeedKind.quick,
          dayKey: '2026-10-20',
          slotIndex: 2,
        );
        await r.insert(item);
        await r.update(
          item.copyWith(
            status: StudyFeedStatus.scheduled,
            scheduledAt: DateTime(2026, 10, 20, 8, 0),
          ),
        );
        final StudyFeedItem? got = await r.getById('sf_upd');
        expect(got!.status, StudyFeedStatus.scheduled);
        expect(got.scheduledAt, DateTime(2026, 10, 20, 8, 0));
      } finally {
        await app.close();
      }
    });
  }); // end CRUD

  group('StudyFeedRepository — chống trùng (dedup)', () {
    test('insert cùng dedup_key lần thứ hai trả false', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        expect(
          await r.insert(makeItem(
            id: 'sf_a',
            kind: StudyFeedKind.lesson,
            dayKey: '2026-10-20',
            slotIndex: 0,
            dedupKey: 'dup_key_1',
          )),
          isTrue,
        );
        expect(
          await r.insert(makeItem(
            id: 'sf_b',
            kind: StudyFeedKind.lesson,
            dayKey: '2026-10-21',
            slotIndex: 0,
            dedupKey: 'dup_key_1',
          )),
          isFalse,
        );
        expect(await r.getById('sf_b'), isNull);
      } finally {
        await app.close();
      }
    });

    test('cùng (day_key, kind, slot_index) chỉ chèn được 1 dòng', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        expect(
          await r.insert(makeItem(
            id: 'sf_slot',
            kind: StudyFeedKind.quick,
            dayKey: '2026-10-20',
            slotIndex: 3,
            dedupKey: 'dk_a',
          )),
          isTrue,
        );
        expect(
          await r.insert(makeItem(
            id: 'sf_slot2',
            kind: StudyFeedKind.quick,
            dayKey: '2026-10-20',
            slotIndex: 3,
            dedupKey: 'dk_b',
          )),
          isFalse,
        );
      } finally {
        await app.close();
      }
    });

    test('khác ngày cùng slot + kind cho phép chèn', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        expect(
          await r.insert(makeItem(
            id: 'sf_d1',
            kind: StudyFeedKind.quick,
            dayKey: '2026-10-20',
            slotIndex: 0,
            dedupKey: 'dk_d1',
          )),
          isTrue,
        );
        expect(
          await r.insert(makeItem(
            id: 'sf_d2',
            kind: StudyFeedKind.quick,
            dayKey: '2026-10-21',
            slotIndex: 0,
            dedupKey: 'dk_d2',
          )),
          isTrue,
        );
      } finally {
        await app.close();
      }
    });

    test('existsDedupKey tìm đúng/không đúng', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        await r.insert(makeItem(
          id: 'sf_ex',
          kind: StudyFeedKind.lesson,
          dayKey: '2026-10-20',
          slotIndex: 0,
          dedupKey: 'ex_key',
        ));
        expect(await r.existsDedupKey('ex_key'), isTrue);
        expect(await r.existsDedupKey('khong_co'), isFalse);
      } finally {
        await app.close();
      }
    });
  }); // end dedup

  group('StudyFeedRepository — truy vấn theo trạng thái/quota', () {
    test('listByDayKind trả đúng thứ tự slot_index', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        await r.insert(makeItem(id: 'q1', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 2));
        await r.insert(makeItem(id: 'q2', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 0));
        await r.insert(makeItem(id: 'l1', kind: StudyFeedKind.lesson, dayKey: '2026-10-20', slotIndex: 1));
        final List<StudyFeedItem> quick = await r.listByDayKind('2026-10-20', StudyFeedKind.quick);
        expect(quick.map((e) => e.slotIndex), <int>[0, 2]);
        final List<StudyFeedItem> lessons = await r.listByDayKind('2026-10-20', StudyFeedKind.lesson);
        expect(lessons.map((e) => e.slotIndex), <int>[1]);
      } finally {
        await app.close();
      }
    });

    test('listActiveRange không trả cancelled', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        await r.insert(makeItem(id: 'a1', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 0, status: StudyFeedStatus.queued));
        await r.insert(makeItem(id: 'a2', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 1, status: StudyFeedStatus.cancelled));
        await r.insert(makeItem(id: 'a3', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 2, status: StudyFeedStatus.error));
        final List<StudyFeedItem> active = await r.listActiveRange('2026-10-20', '2026-10-20');
        expect(active.map((e) => e.id).toSet(), <String>{'a1', 'a3'});
      } finally {
        await app.close();
      }
    });

    test('countActive chỉ tính active của một kind trong một ngày', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        await r.insert(makeItem(id: 'c1', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 0));
        await r.insert(makeItem(id: 'c2', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 1));
        await r.insert(makeItem(id: 'c3', kind: StudyFeedKind.lesson, dayKey: '2026-10-20', slotIndex: 0));
        await r.insert(makeItem(id: 'c4', kind: StudyFeedKind.quick, dayKey: '2026-10-21', slotIndex: 0));
        expect(await r.countActive('2026-10-20', StudyFeedKind.quick), 2);
        expect(await r.countActive('2026-10-20', StudyFeedKind.lesson), 1);
        expect(await r.countActive('2026-10-21', StudyFeedKind.quick), 1);
      } finally {
        await app.close();
      }
    });

    test('listByStatus lọc theo nhiều status', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        await r.insert(makeItem(id: 's1', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 0, status: StudyFeedStatus.ready));
        await r.insert(makeItem(id: 's2', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 1, status: StudyFeedStatus.scheduled));
        await r.insert(makeItem(id: 's3', kind: StudyFeedKind.quick, dayKey: '2026-10-20', slotIndex: 2, status: StudyFeedStatus.error));
        final List<StudyFeedItem> rows = await r.listByStatus(
          <StudyFeedStatus>[StudyFeedStatus.ready, StudyFeedStatus.error],
        );
        expect(rows.map((e) => e.id).toSet(), <String>{'s1', 's3'});
      } finally {
        await app.close();
      }
    });

    test('markOpened chuyển scheduled/delivered sang opened theo refId', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        await r.insert(makeItem(id: 'm1', kind: StudyFeedKind.lesson, dayKey: '2026-10-20', slotIndex: 0, status: StudyFeedStatus.scheduled, refId: 'ls_ref'));
        await r.insert(makeItem(id: 'm2', kind: StudyFeedKind.lesson, dayKey: '2026-10-20', slotIndex: 1, status: StudyFeedStatus.delivered, refId: 'ls_ref2'));
        await r.insert(makeItem(id: 'm3', kind: StudyFeedKind.lesson, dayKey: '2026-10-20', slotIndex: 2, status: StudyFeedStatus.queued, refId: 'ls_ref3'));
        await r.markOpened('ls_ref');
        await r.markOpened('ls_ref2');
        await r.markOpened('ls_ref3');
        expect((await r.getById('m1'))!.status, StudyFeedStatus.opened);
        expect((await r.getById('m2'))!.status, StudyFeedStatus.opened);
        expect((await r.getById('m3'))!.status, StudyFeedStatus.queued);
      } finally {
        await app.close();
      }
    });
  }); // end truy vấn

  group('StudyFeedRepository — isActive / hasContent', () {
    test('isActive đúng cho mọi status trừ cancelled', () async {
      final AppDatabase app = await openDb();
      try {
        final StudyFeedRepository r = repo(app);
        for (final StudyFeedStatus s in StudyFeedStatus.values) {
          await r.insert(makeItem(
            id: 'is_${s.dbValue}',
            kind: StudyFeedKind.quick,
            dayKey: '2026-10-20',
            slotIndex: StudyFeedStatus.values.indexOf(s),
            status: s,
          ));
          final StudyFeedItem? got = await r.getById('is_${s.dbValue}');
          expect(got!.status.isActive, s != StudyFeedStatus.cancelled,
              reason: '$s isActive=${s.isActive}');
        }
      } finally {
        await app.close();
      }
    });

    test('hasContent đúng chỉ khi ready trở lên', () {
      expect(StudyFeedStatus.queued.hasContent, isFalse);
      expect(StudyFeedStatus.ready.hasContent, isTrue);
      expect(StudyFeedStatus.scheduled.hasContent, isTrue);
      expect(StudyFeedStatus.delivered.hasContent, isTrue);
      expect(StudyFeedStatus.opened.hasContent, isTrue);
      expect(StudyFeedStatus.error.hasContent, isFalse);
      expect(StudyFeedStatus.cancelled.hasContent, isFalse);
    });
  });

  test('studyDayKey tạo khóa ngày địa phương yyyy-MM-dd', () {
    expect(studyDayKey(DateTime(2026, 10, 20, 14, 30)), '2026-10-20');
    expect(studyDayKey(DateTime(2026, 1, 5, 0, 0)), '2026-01-05');
    expect(studyDayKey(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
  });
}
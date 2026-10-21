import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/study_feed_item.dart';

/// CRUD hàng đợi kế hoạch học (bảng `study_feed_items`).
///
/// Chống trùng ở tầng DB: UNIQUE `dedup_key` (không kế hoạch trùng một nội
/// dung) và UNIQUE `(day_key, kind, slot_index)` (idempotent khi chạy lại
/// scheduler — không thể có 2 dòng cùng khung giờ).
class StudyFeedRepository {
  StudyFeedRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  static final Set<String> _activeStatuses = <String>{
    StudyFeedStatus.queued.dbValue,
    StudyFeedStatus.ready.dbValue,
    StudyFeedStatus.scheduled.dbValue,
    StudyFeedStatus.delivered.dbValue,
    StudyFeedStatus.opened.dbValue,
    StudyFeedStatus.error.dbValue,
  };

  /// Thêm dòng mới. Trả `false` nếu đã tồn tại dedup_key hoặc khung giờ
  /// (idempotent — chạy lại scheduler không tạo trùng).
  Future<bool> insert(StudyFeedItem item) async {
    try {
      await _db.insert(
        'study_feed_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return true;
    } on DatabaseException {
      return false;
    }
  }

  Future<StudyFeedItem?> getById(String id) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'study_feed_items',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return StudyFeedItem.fromMap(rows.first);
  }

  /// Có dòng KHÁC đang giữ [dedupKey] không? ([excludeId] = dòng hiện tại
  /// khi kiểm tra lại ngay trước khi gán key.)
  Future<bool> existsDedupKey(String dedupKey, {String? excludeId}) async {
    final String where = excludeId == null
        ? 'dedup_key = ?'
        : 'dedup_key = ? AND id != ?';
    final List<Object> args = excludeId == null
        ? <Object>[dedupKey]
        : <Object>[dedupKey, excludeId];
    final List<Map<String, Object?>> rows = await _db.query(
      'study_feed_items',
      columns: <String>['id'],
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<StudyFeedItem>> listByDayKind(
    String dayKey,
    StudyFeedKind kind,
  ) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'study_feed_items',
      where: 'day_key = ? AND kind = ?',
      whereArgs: <Object>[dayKey, kind.dbValue],
      orderBy: 'slot_index ASC',
    );
    return rows.map(StudyFeedItem.fromMap).toList(growable: false);
  }

  /// Các dòng đang chiếm khung giờ (tính quota) trong khoảng ngày [fromKey]
  /// → [toKey] (kể cả `error` để không cấp thêm quota cho nội dung lỗi).
  Future<List<StudyFeedItem>> listActiveRange(
    String fromKey,
    String toKey,
  ) async {
    final List<String> statuses = _activeStatuses.toList(growable: false);
    final List<Map<String, Object?>> rows = await _db.query(
      'study_feed_items',
      where:
          'day_key >= ? AND day_key <= ? AND status IN '
          '(${List<String>.filled(statuses.length, '?').join(',')})',
      whereArgs: <Object>[fromKey, toKey, ...statuses],
      orderBy: 'day_key ASC, kind ASC, slot_index ASC',
    );
    return rows.map(StudyFeedItem.fromMap).toList(growable: false);
  }

  Future<List<StudyFeedItem>> listByStatus(
    List<StudyFeedStatus> statuses, {
    String? dayKey,
  }) async {
    final List<String> values = statuses
        .map((StudyFeedStatus s) => s.dbValue)
        .toList(growable: false);
    final List<String> where = <String>[
      'status IN (${List<String>.filled(values.length, '?').join(',')})',
    ];
    final List<Object> args = <Object>[...values];
    if (dayKey != null) {
      where.add('day_key = ?');
      args.add(dayKey);
    }
    final List<Map<String, Object?>> rows = await _db.query(
      'study_feed_items',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'scheduled_at ASC, day_key ASC, slot_index ASC',
    );
    return rows.map(StudyFeedItem.fromMap).toList(growable: false);
  }

  /// Số dòng đang chiếm khung giờ của một loại trong một ngày (quota hiện tại).
  Future<int> countActive(String dayKey, StudyFeedKind kind) async {
    final List<String> statuses = _activeStatuses.toList(growable: false);
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COUNT(*) AS total FROM study_feed_items '
      'WHERE day_key = ? AND kind = ? AND status IN '
      '(${List<String>.filled(statuses.length, '?').join(',')})',
      <Object>[
        dayKey,
        kind.dbValue,
        ...statuses,
      ],
    );
    return ((rows.first['total'] ?? 0) as num).toInt();
  }

  Future<void> update(StudyFeedItem item) async {
    final StudyFeedItem updated = item.copyWith(
      updatedAt: DateTime.now().toUtc(),
    );
    await _db.update(
      'study_feed_items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[item.id],
    );
  }

  /// Ghi nhận người dùng đã mở nội dung (delivered/opened) — không đụng nội
  /// dung thật hay lịch FSRS.
  Future<void> markOpened(String refId) async {
    await _db.update(
      'study_feed_items',
      <String, Object?>{
        'status': StudyFeedStatus.opened.dbValue,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where:
          'ref_id = ? AND status IN (?, ?)',
      whereArgs: <Object>[
        refId,
        StudyFeedStatus.scheduled.dbValue,
        StudyFeedStatus.delivered.dbValue,
      ],
    );
  }
}

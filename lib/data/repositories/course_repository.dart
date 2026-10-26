import 'package:sqflite/sqflite.dart';

import '../../core/utils/id_generator.dart';
import '../db/app_database.dart';
import '../models/course.dart';

/// CRUD khóa học + đề cương (bảng `courses`, `course_items`).
class CourseRepository {
  CourseRepository(this._app);

  final AppDatabase _app;

  Database get _db => _app.db;

  /// Tạo khóa học cùng toàn bộ đề cương trong một transaction.
  Future<Course> createWithOutline({
    required String topicId,
    required String name,
    required CourseLevel level,
    required List<String> titles,
    int perDay = 1,
    DateTime? now,
  }) async {
    final DateTime ts = (now ?? DateTime.now()).toUtc();
    final List<String> clean = <String>[
      for (final String t in titles)
        if (t.trim().isNotEmpty) t.trim(),
    ];
    final Course course = Course(
      id: newId('co'),
      topicId: topicId,
      name: name,
      level: level,
      totalItems: clean.length,
      perDay: perDay < 1 ? 1 : perDay,
      createdAt: ts,
      updatedAt: ts,
    );
    await _db.transaction((Transaction txn) async {
      await txn.insert('courses', course.toMap());
      for (int i = 0; i < clean.length; i++) {
        final CourseItem item = CourseItem(
          id: newId('ci'),
          courseId: course.id,
          position: i,
          title: clean[i],
          createdAt: ts,
          updatedAt: ts,
        );
        await txn.insert('course_items', item.toMap());
      }
    });
    return course;
  }

  Future<Course?> getById(String id) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'courses',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : Course.fromMap(rows.first);
  }

  Future<List<Course>> list({CourseStatus? status}) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'courses',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : <Object>[status.dbValue],
      orderBy: 'created_at ASC',
    );
    return rows.map(Course.fromMap).toList(growable: false);
  }

  Future<void> updateCourse(Course course) async {
    final Course updated = course.copyWith(updatedAt: DateTime.now().toUtc());
    await _db.update(
      'courses',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[course.id],
    );
  }

  Future<void> deleteCourse(String id) async {
    await _db.delete('courses', where: 'id = ?', whereArgs: <Object>[id]);
  }

  Future<CourseItem?> getItem(String id) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'course_items',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : CourseItem.fromMap(rows.first);
  }

  Future<CourseItem?> getItemByKnowledge(String knowledgeItemId) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'course_items',
      where: 'knowledge_item_id = ?',
      whereArgs: <Object>[knowledgeItemId],
      limit: 1,
    );
    return rows.isEmpty ? null : CourseItem.fromMap(rows.first);
  }

  Future<List<CourseItem>> listItems(String courseId) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'course_items',
      where: 'course_id = ?',
      whereArgs: <Object>[courseId],
      orderBy: 'position ASC',
    );
    return rows.map(CourseItem.fromMap).toList(growable: false);
  }

  Future<void> updateItem(CourseItem item) async {
    final CourseItem updated = item.copyWith(
      updatedAt: DateTime.now().toUtc(),
    );
    await _db.update(
      'course_items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[item.id],
    );
  }

  /// Thêm một mẩu vào cuối đề cương (mở rộng khóa học).
  Future<CourseItem> appendItem(String courseId, String title) async {
    final DateTime ts = DateTime.now().toUtc();
    late CourseItem item;
    await _db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.rawQuery(
        'SELECT COALESCE(MAX(position), -1) AS p FROM course_items '
        'WHERE course_id = ?',
        <Object>[courseId],
      );
      final int next = ((rows.first['p'] ?? -1) as num).toInt() + 1;
      item = CourseItem(
        id: newId('ci'),
        courseId: courseId,
        position: next,
        title: title.trim(),
        createdAt: ts,
        updatedAt: ts,
      );
      await txn.insert('course_items', item.toMap());
      await txn.update(
        'courses',
        <String, Object?>{
          'total_items': next + 1,
          'updated_at': ts.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: <Object>[courseId],
      );
    });
    return item;
  }

  /// Các mẩu đã có nội dung nhưng chưa đọc, đã đến giờ phát hành ([asOf]),
  /// của khóa đang chạy — danh sách "Chưa đọc" ở trang chủ.
  Future<List<CourseItemEntry>> listUnread({required DateTime asOf}) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT i.*, c.topic_id AS c_topic_id, c.name AS c_name, '
      'c.level AS c_level, c.total_items AS c_total, c.per_day AS c_per_day, '
      'c.status AS c_status, c.created_at AS c_created, '
      'c.updated_at AS c_updated '
      'FROM course_items i JOIN courses c ON c.id = i.course_id '
      "WHERE i.status = 'ready' AND c.status = 'active' "
      'AND (i.release_at IS NULL OR i.release_at <= ?) '
      'ORDER BY i.release_at ASC, c.created_at ASC, i.position ASC',
      <Object>[asOf.toUtc().millisecondsSinceEpoch],
    );
    return rows.map(_entry).toList(growable: false);
  }

  /// Các mẩu đã sinh nội dung, chưa đọc, có giờ phát hành ở tương lai
  /// (cần lên lịch thông báo).
  Future<List<CourseItemEntry>> listUpcoming({required DateTime asOf}) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT i.*, c.topic_id AS c_topic_id, c.name AS c_name, '
      'c.level AS c_level, c.total_items AS c_total, c.per_day AS c_per_day, '
      'c.status AS c_status, c.created_at AS c_created, '
      'c.updated_at AS c_updated '
      'FROM course_items i JOIN courses c ON c.id = i.course_id '
      "WHERE i.status = 'ready' AND c.status = 'active' "
      'AND i.release_at IS NOT NULL AND i.release_at > ? '
      'ORDER BY i.release_at ASC',
      <Object>[asOf.toUtc().millisecondsSinceEpoch],
    );
    return rows.map(_entry).toList(growable: false);
  }

  /// Số mẩu có `release_at` trong khoảng [from, to) của một khóa học
  /// (kiểm soát quota mỗi ngày).
  Future<int> countReleasedBetween(
    String courseId,
    DateTime from,
    DateTime to,
  ) async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COUNT(*) AS n FROM course_items WHERE course_id = ? '
      'AND release_at IS NOT NULL AND release_at >= ? AND release_at < ?',
      <Object>[
        courseId,
        from.toUtc().millisecondsSinceEpoch,
        to.toUtc().millisecondsSinceEpoch,
      ],
    );
    return ((rows.first['n'] ?? 0) as num).toInt();
  }

  CourseItemEntry _entry(Map<String, Object?> row) {
    final Course course = Course.fromMap(<String, Object?>{
      'id': row['course_id'],
      'topic_id': row['c_topic_id'],
      'name': row['c_name'],
      'level': row['c_level'],
      'total_items': row['c_total'],
      'per_day': row['c_per_day'],
      'status': row['c_status'],
      'created_at': row['c_created'],
      'updated_at': row['c_updated'],
    });
    return CourseItemEntry(course: course, item: CourseItem.fromMap(row));
  }
}

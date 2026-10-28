import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../data/db/app_database.dart';
import '../../data/db/schema.dart';
import 'notification_service.dart';
import 'preferences_service.dart';

/// Lỗi sao lưu/khôi phục với thông điệp tiếng Việt hiển thị thẳng cho người dùng.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Phần đầu của file `.mkbackup`.
class BackupHeader {
  const BackupHeader({
    required this.format,
    required this.version,
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.counts,
  });

  final String format;
  final int version;
  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final Map<String, int> counts;

  Map<String, Object?> toJson() => <String, Object?>{
    'format': format,
    'version': version,
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'counts': counts,
  };
}

/// File sao lưu đã đọc và kiểm tra hợp lệ, chưa ghi vào DB.
class BackupPreview {
  const BackupPreview({
    required this.header,
    required this.tables,
    required this.prefs,
  });

  final BackupHeader header;
  final Map<String, List<Map<String, Object?>>> tables;
  final Map<String, Object?> prefs;

  int get totalRows =>
      header.counts.values.fold<int>(0, (int a, int b) => a + b);
}

/// Kết quả khôi phục.
class RestoreResult {
  const RestoreResult({
    required this.counts,
    required this.safetyBackupPath,
    required this.notificationsDisabled,
  });

  final Map<String, int> counts;

  /// Đường dẫn file sao lưu an toàn tự tạo ngay trước khi ghi đè.
  final String safetyBackupPath;

  /// true khi thiếu quyền thông báo nên các cờ nhắc đã bị tắt.
  final bool notificationsDisabled;
}

/// Sao lưu / khôi phục toàn bộ dữ liệu cục bộ ra file `.mkbackup` (JSON).
///
/// - Gồm mọi bảng SQLite + prefs người dùng ([PreferencesService.backupKeys]).
/// - KHÔNG gồm: khóa API / cấu hình AI, phiên chạy, ID thông báo đã lập, file media.
/// - Không cloud, không tài khoản: file do người dùng tự lưu/chép.
class BackupService {
  BackupService({
    required this.database,
    required this.prefs,
    required this.notifications,
    this.appVersion = '1.0.0',
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase database;
  final PreferencesService prefs;
  final NotificationService notifications;
  final String appVersion;
  final DateTime Function() _clock;

  static const String formatId = 'mindkeeper-backup';
  static const int formatVersion = 1;
  static const String fileExtension = 'mkbackup';

  /// Thứ tự bảng an toàn cho khóa ngoại (cha trước, con sau).
  static const List<String> tableOrder = <String>[
    'topics',
    'lessons',
    'sources',
    'knowledge_items',
    'review_cards',
    'review_logs',
    'knowledge_generation_tasks',
    'knowledge_reminder_history',
    'study_feed_items',
    'courses',
    'course_items',
  ];

  Database get _db => database.db;

  // ---------------------------------------------------------------- export

  /// Tên file gợi ý, vd. `mindkeeper-20261028-103000.mkbackup`.
  String suggestedFileName() {
    final DateTime t = _clock();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'mindkeeper-${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}.$fileExtension';
  }

  /// Dựng nội dung JSON sao lưu từ dữ liệu hiện tại.
  Future<String> exportJson() async {
    final Map<String, List<Map<String, Object?>>> tables =
        <String, List<Map<String, Object?>>>{};
    final Map<String, int> counts = <String, int>{};
    await _db.transaction((Transaction txn) async {
      for (final String table in tableOrder) {
        final List<Map<String, Object?>> rows = await txn.query(table);
        tables[table] = <Map<String, Object?>>[
          for (final Map<String, Object?> row in rows)
            Map<String, Object?>.of(row),
        ];
        counts[table] = rows.length;
      }
    });
    final BackupHeader header = BackupHeader(
      format: formatId,
      version: formatVersion,
      schemaVersion: DbSchema.currentVersion,
      exportedAt: _clock().toUtc(),
      appVersion: appVersion,
      counts: counts,
    );
    return jsonEncode(<String, Object?>{
      'header': header.toJson(),
      'prefs': prefs.exportBackupPrefs(),
      'tables': tables,
    });
  }

  // ------------------------------------------------------------------ parse

  /// Đọc + kiểm tra file sao lưu. Ném [BackupException] với lý do rõ ràng.
  BackupPreview parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const BackupException(
        'File không phải bản sao lưu MindKeeper (không đọc được dữ liệu JSON).',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw const BackupException('File không đúng định dạng sao lưu.');
    }
    final Object? rawHeader = decoded['header'];
    if (rawHeader is! Map<String, Object?>) {
      throw const BackupException(
        'File thiếu phần đầu (header) của bản sao lưu.',
      );
    }
    if (rawHeader['format'] != formatId) {
      throw const BackupException(
        'File không phải bản sao lưu MindKeeper (.mkbackup).',
      );
    }
    final Object? version = rawHeader['version'];
    if (version is! int || version < 1) {
      throw const BackupException('Phiên bản định dạng sao lưu không hợp lệ.');
    }
    if (version > formatVersion) {
      throw BackupException(
        'Bản sao lưu dùng định dạng mới hơn (v$version). Hãy cập nhật MindKeeper '
        'rồi thử lại.',
      );
    }
    final Object? schemaVersion = rawHeader['schemaVersion'];
    if (schemaVersion is! int || schemaVersion < 1) {
      throw const BackupException('Phiên bản dữ liệu (schema) không hợp lệ.');
    }
    if (schemaVersion > DbSchema.currentVersion) {
      throw BackupException(
        'Bản sao lưu được tạo bởi phiên bản MindKeeper mới hơn (dữ liệu v$schemaVersion, '
        'ứng dụng này hỗ trợ tới v${DbSchema.currentVersion}). Hãy cập nhật ứng dụng.',
      );
    }
    final DateTime? exportedAt = DateTime.tryParse(
      '${rawHeader['exportedAt'] ?? ''}',
    );
    if (exportedAt == null) {
      throw const BackupException('Thời điểm xuất trong file không hợp lệ.');
    }
    final Object? rawTables = decoded['tables'];
    if (rawTables is! Map<String, Object?>) {
      throw const BackupException('File thiếu phần dữ liệu các bảng.');
    }
    final Object? rawCounts = rawHeader['counts'];
    if (rawCounts is! Map<String, Object?>) {
      throw const BackupException('File thiếu thống kê số lượng (counts).');
    }

    final Map<String, List<Map<String, Object?>>> tables =
        <String, List<Map<String, Object?>>>{};
    final Map<String, int> counts = <String, int>{};
    for (final String table in tableOrder) {
      final Object? rows = rawTables[table];
      if (rows == null) {
        tables[table] = const <Map<String, Object?>>[];
        counts[table] = 0;
        continue;
      }
      if (rows is! List<Object?>) {
        throw BackupException('Bảng "$table" trong file không hợp lệ.');
      }
      final List<Map<String, Object?>> parsed = <Map<String, Object?>>[];
      for (final Object? row in rows) {
        if (row is! Map<String, Object?>) {
          throw BackupException('Bảng "$table" có dòng dữ liệu hỏng.');
        }
        for (final Object? value in row.values) {
          if (value != null &&
              value is! num &&
              value is! String &&
              value is! bool) {
            throw BackupException('Bảng "$table" có giá trị không hợp lệ.');
          }
        }
        parsed.add(row);
      }
      final Object? declared = rawCounts[table];
      if (declared is int && declared != parsed.length) {
        throw BackupException(
          'File bị thiếu hoặc hỏng: bảng "$table" khai báo $declared dòng nhưng '
          'chỉ có ${parsed.length}.',
        );
      }
      tables[table] = parsed;
      counts[table] = parsed.length;
    }

    final Object? rawPrefs = decoded['prefs'];
    return BackupPreview(
      header: BackupHeader(
        format: formatId,
        version: version,
        schemaVersion: schemaVersion,
        exportedAt: exportedAt,
        appVersion: '${rawHeader['appVersion'] ?? ''}',
        counts: counts,
      ),
      tables: tables,
      prefs: rawPrefs is Map<String, Object?>
          ? rawPrefs
          : const <String, Object?>{},
    );
  }

  // ---------------------------------------------------------------- restore

  /// Thay TOÀN BỘ dữ liệu hiện tại bằng [preview].
  ///
  /// Trình tự: (1) ghi file sao lưu an toàn của dữ liệu hiện tại vào
  /// [safetyDir]; (2) xóa + nạp lại mọi bảng trong MỘT transaction — lỗi thì
  /// rollback, dữ liệu cũ nguyên vẹn; (3) khôi phục prefs; (4) hủy lịch thông
  /// báo cũ, tắt cờ nhắc nếu thiếu quyền, rồi gọi [rescheduleAll].
  Future<RestoreResult> restore(
    BackupPreview preview, {
    required Directory safetyDir,
    Future<void> Function()? rescheduleAll,
  }) async {
    // (1) Sao lưu an toàn trước khi ghi đè.
    final String safetyPath;
    try {
      await safetyDir.create(recursive: true);
      final String json = await exportJson();
      safetyPath = p.join(
        safetyDir.path,
        'truoc-khoi-phuc-${_clock().millisecondsSinceEpoch}.$fileExtension',
      );
      await File(safetyPath).writeAsString(json, flush: true);
    } catch (e) {
      throw BackupException(
        'Không tạo được bản sao lưu an toàn trước khi khôi phục nên đã huỷ, dữ liệu '
        'hiện tại không bị thay đổi. ($e)',
      );
    }

    // (2) Ghi đè trong transaction.
    try {
      await _db.transaction((Transaction txn) async {
        for (final String table in tableOrder.reversed) {
          await txn.delete(table);
        }
        for (final String table in tableOrder) {
          final Set<String> columns = <String>{
            for (final Map<String, Object?> info in await txn.rawQuery(
              'PRAGMA table_info($table)',
            ))
              info['name']! as String,
          };
          for (final Map<String, Object?> source in preview.tables[table]!) {
            final Map<String, Object?> row = <String, Object?>{
              for (final MapEntry<String, Object?> e in source.entries)
                if (columns.contains(e.key))
                  e.key: e.value is bool ? (e.value! as bool ? 1 : 0) : e.value,
            };
            if (table == 'sources' && _isAbsolutePath(row['storage_path'])) {
              // File media không nằm trong sao lưu → đường dẫn tuyệt đối vô nghĩa.
              row['storage_path'] = null;
            }
            await txn.insert(table, row);
          }
        }
        final List<Map<String, Object?>> broken = await txn.rawQuery(
          'PRAGMA foreign_key_check',
        );
        if (broken.isNotEmpty) {
          throw BackupException(
            'File sao lưu có dữ liệu tham chiếu sai (${broken.length} lỗi khóa ngoại).',
          );
        }
      });
    } on BackupException {
      rethrow;
    } catch (e) {
      throw BackupException(
        'Khôi phục thất bại, dữ liệu hiện tại được giữ nguyên. Bản sao lưu an toàn: '
        '$safetyPath. Chi tiết: $e',
      );
    }

    // (3) Prefs người dùng.
    await prefs.restoreBackupPrefs(preview.prefs);

    // (4) Thông báo: hủy cũ, tắt cờ nếu thiếu quyền, lập lại.
    bool disabled = false;
    try {
      await notifications.cancelAll();
    } catch (_) {
      // Plugin chưa sẵn sàng (vd. môi trường test) — lập lại lịch bên dưới.
    }
    await prefs.setKnowledgeReminderScheduledIds(const <int>[]);
    final bool? allowed = await notifications.areNotificationsEnabled();
    if (allowed == false) {
      await prefs.setNotificationsEnabled(false);
      await prefs.setKnowledgeReminderEnabled(false);
      await prefs.setKnowledgeReadingEnabled(false);
      await prefs.setStudyPlanNewContentNotifications(false);
      disabled = true;
    }
    if (rescheduleAll != null) {
      try {
        await rescheduleAll();
      } catch (_) {
        // Lập lại lịch lỗi không được làm mất dữ liệu đã khôi phục; lịch sẽ tự
        // lập lại ở lần mở app sau.
      }
    }
    return RestoreResult(
      counts: Map<String, int>.of(preview.header.counts),
      safetyBackupPath: safetyPath,
      notificationsDisabled: disabled,
    );
  }

  static bool _isAbsolutePath(Object? value) {
    if (value is! String || value.isEmpty) return false;
    return value.startsWith('/') ||
        value.startsWith(r'\') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value) ||
        value.contains('://');
  }
}

import 'package:sqflite/sqflite.dart';

class SchemaMigration {
  const SchemaMigration({
    required this.fromVersion,
    required this.toVersion,
    required this.upgrade,
  });

  final int fromVersion;
  final int toVersion;
  final Future<void> Function(DatabaseExecutor db) upgrade;
}

abstract final class DbSchema {
  /// Phiên bản schema hiện tại của ứng dụng.
  static const int currentVersion = 8;

  static const String topics = '''
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
)''';

  static const String sources = '''
CREATE TABLE sources (
  id TEXT PRIMARY KEY,
  topic_id TEXT REFERENCES topics(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  storage_path TEXT,
  content_text TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'ready',
  reference_url TEXT,
  reference_location TEXT,
  error_message TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''';

  static const String knowledgeItems = '''
CREATE TABLE knowledge_items (
  id TEXT PRIMARY KEY,
  topic_id TEXT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  source_id TEXT REFERENCES sources(id) ON DELETE SET NULL,
  lesson_id TEXT REFERENCES lessons(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  details TEXT NOT NULL DEFAULT '',
  origin TEXT NOT NULL DEFAULT 'user_confirmed',
  is_favorite INTEGER NOT NULL DEFAULT 0,
  is_paused INTEGER NOT NULL DEFAULT 0,
  started_at INTEGER,
  last_read_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''';

  static const String reviewCards = '''
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
)''';

  static const String reviewLogs = '''
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
)''';

  /// Bài học AI khám phá kiến thức: lưu trọn gói nội dung để không sinh lại.
  static const String lessons = '''
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
)''';

  /// Theo dõi tiến độ sinh thư viện kiến thức cho chủ đề.
  static const String knowledgeGenerationTasks = '''
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
)''';

  static const String knowledgeReminderHistory = '''
CREATE TABLE knowledge_reminder_history (
  id TEXT PRIMARY KEY,
  lesson_id TEXT NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  snippet_key TEXT NOT NULL,
  snippet TEXT NOT NULL,
  sent_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)''';

  /// Hàng đợi kế hoạch học chủ động (GĐ17): một dòng = một nội dung mới
  /// dự kiến phát hành trong một khung giờ của một ngày địa phương.
  /// KHÔNG chứa nội dung bài — nội dung thật vẫn nằm trong `lessons` /
  /// `knowledge_items` (qua `ref_id`), nên xóa/khôi phục hàng đợi không mất
  /// dữ liệu đã học.
  static const String studyFeedItems = '''
CREATE TABLE study_feed_items (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  topic_id TEXT REFERENCES topics(id) ON DELETE SET NULL,
  topic_name TEXT NOT NULL DEFAULT '',
  day_key TEXT NOT NULL,
  slot_index INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'queued',
  ref_id TEXT,
  dedup_key TEXT NOT NULL,
  scheduled_at INTEGER,
  error TEXT,
  retryable INTEGER NOT NULL DEFAULT 0,
  next_retry_at INTEGER,
  attempts INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''';

  static const List<String> studyFeedIndexes = <String>[
    'CREATE UNIQUE INDEX idx_feed_dedup ON study_feed_items(dedup_key)',
    'CREATE UNIQUE INDEX idx_feed_slot ON study_feed_items(day_key, kind, slot_index)',
    'CREATE INDEX idx_feed_day ON study_feed_items(day_key)',
    'CREATE INDEX idx_feed_status ON study_feed_items(status)',
  ];

  static const List<String> lessonIndexes = <String>[
    'CREATE UNIQUE INDEX idx_lessons_dedup ON lessons(dedup_key)',
    'CREATE INDEX idx_lessons_domain ON lessons(domain_id)',
    'CREATE INDEX idx_lessons_linked_topic ON lessons(linked_topic_id)',
  ];

  static const List<String> indexes = <String>[
    'CREATE INDEX idx_sources_topic ON sources(topic_id)',
    'CREATE INDEX idx_knowledge_topic ON knowledge_items(topic_id)',
    'CREATE INDEX idx_knowledge_source ON knowledge_items(source_id)',
    'CREATE INDEX idx_knowledge_lesson ON knowledge_items(lesson_id)',
    'CREATE INDEX idx_cards_item ON review_cards(knowledge_item_id)',
    'CREATE INDEX idx_cards_due ON review_cards(due_at)',
    'CREATE INDEX idx_logs_card ON review_logs(card_id)',
    'CREATE INDEX idx_logs_time ON review_logs(reviewed_at)',
    'CREATE INDEX idx_topics_name ON topics(name)',
    ...lessonIndexes,
    ...studyFeedIndexes,
  ];

  static const List<String> tables = <String>[
    topics,
    sources,
    knowledgeItems,
    reviewCards,
    reviewLogs,
    lessons,
    knowledgeGenerationTasks,
    knowledgeReminderHistory,
    studyFeedItems,
  ];

  /// Dãy migration chính thức của ứng dụng.
  static const List<SchemaMigration> migrations = <SchemaMigration>[
    SchemaMigration(fromVersion: 1, toVersion: 2, upgrade: _upgradeToV2),
    SchemaMigration(fromVersion: 2, toVersion: 3, upgrade: _upgradeToV3),
    SchemaMigration(fromVersion: 3, toVersion: 4, upgrade: _upgradeToV4),
    SchemaMigration(fromVersion: 4, toVersion: 5, upgrade: _upgradeToV5),
    SchemaMigration(fromVersion: 5, toVersion: 6, upgrade: _upgradeToV6),
    SchemaMigration(fromVersion: 6, toVersion: 7, upgrade: _upgradeToV7),
    SchemaMigration(fromVersion: 7, toVersion: 8, upgrade: _upgradeToV8),
  ];

  static Future<void> _upgradeToV2(DatabaseExecutor db) async {
    await db.execute(sources);
    await db.execute(reviewCards);
    await db.execute(reviewLogs);
    await db.execute(lessons);
    for (final String statement in lessonIndexes) {
      await db.execute(statement);
    }
    await db.execute('CREATE INDEX idx_sources_topic ON sources(topic_id)');
    await db.execute(
      'CREATE INDEX idx_cards_item ON review_cards(knowledge_item_id)',
    );
    await db.execute('CREATE INDEX idx_cards_due ON review_cards(due_at)');
    await db.execute('CREATE INDEX idx_logs_card ON review_logs(card_id)');
    await db.execute('CREATE INDEX idx_logs_time ON review_logs(reviewed_at)');
  }

  static Future<void> _upgradeToV3(DatabaseExecutor db) async {
    await db.execute(knowledgeGenerationTasks);
  }

  static Future<void> _upgradeToV4(DatabaseExecutor db) async {
    // Thêm cột started_at vào knowledge_items để theo dõi thời điểm bắt đầu đọc lần đầu
    await db.execute(
      'ALTER TABLE knowledge_items ADD COLUMN started_at INTEGER',
    );
  }

  static Future<void> _upgradeToV5(DatabaseExecutor db) async {
    // Thêm cột lesson_id vào knowledge_items để liên kết bài học với mục tiêu ghi nhớ
    await db.execute(
      'ALTER TABLE knowledge_items ADD COLUMN lesson_id TEXT REFERENCES lessons(id) ON DELETE SET NULL',
    );
    await db.execute(
      'CREATE INDEX idx_knowledge_lesson ON knowledge_items(lesson_id)',
    );
  }

  static Future<void> _upgradeToV6(DatabaseExecutor db) async {
    // Thêm last_read_at để sort "lần đọc gần nhất" đúng nghĩa,
    // không dùng updated_at (bị thay đổi bởi mọi thao tác sửa/chỉnh sửa).
    await db.execute(
      'ALTER TABLE knowledge_items ADD COLUMN last_read_at INTEGER',
    );
  }

  static Future<void> _upgradeToV7(DatabaseExecutor db) async {
    await db.execute(knowledgeReminderHistory);
  }

  /// GĐ17: chỉ THÊM bảng hàng đợi kế hoạch học + index.
  /// Không ALTER/DROP bảng cũ, không sửa migration đã phát hành — dữ liệu
  /// lessons/knowledge_items/review_cards/review_logs giữ nguyên.
  static Future<void> _upgradeToV8(DatabaseExecutor db) async {
    await db.execute(studyFeedItems);
    for (final String statement in studyFeedIndexes) {
      await db.execute(statement);
    }
  }
}

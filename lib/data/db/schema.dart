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
  static const int currentVersion = 2;

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
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  details TEXT NOT NULL DEFAULT '',
  origin TEXT NOT NULL DEFAULT 'user_confirmed',
  is_favorite INTEGER NOT NULL DEFAULT 0,
  is_paused INTEGER NOT NULL DEFAULT 0,
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

  static const List<String> lessonIndexes = <String>[
    'CREATE UNIQUE INDEX idx_lessons_dedup ON lessons(dedup_key)',
    'CREATE INDEX idx_lessons_domain ON lessons(domain_id)',
    'CREATE INDEX idx_lessons_linked_topic ON lessons(linked_topic_id)',
  ];

  static const List<String> indexes = <String>[
    'CREATE INDEX idx_sources_topic ON sources(topic_id)',
    'CREATE INDEX idx_knowledge_topic ON knowledge_items(topic_id)',
    'CREATE INDEX idx_knowledge_source ON knowledge_items(source_id)',
    'CREATE INDEX idx_cards_item ON review_cards(knowledge_item_id)',
    'CREATE INDEX idx_cards_due ON review_cards(due_at)',
    'CREATE INDEX idx_logs_card ON review_logs(card_id)',
    'CREATE INDEX idx_logs_time ON review_logs(reviewed_at)',
    'CREATE INDEX idx_topics_name ON topics(name)',
    ...lessonIndexes,
  ];

  static const List<String> tables = <String>[
    topics,
    sources,
    knowledgeItems,
    reviewCards,
    reviewLogs,
    lessons,
  ];

  /// Dãy migration chính thức của ứng dụng.
  static const List<SchemaMigration> migrations = <SchemaMigration>[
    SchemaMigration(fromVersion: 1, toVersion: 2, upgrade: _upgradeToV2),
  ];

  static Future<void> _upgradeToV2(DatabaseExecutor db) async {
    await db.execute(lessons);
    for (final String statement in lessonIndexes) {
      await db.execute(statement);
    }
  }
}

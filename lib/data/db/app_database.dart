import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

export 'schema.dart' show SchemaMigration;

class AppDatabase {
  AppDatabase({
    required this.factory,
    this.name = 'mind_keeper.db',
    this.schemaVersion = DbSchema.currentVersion,
    this.migrations = DbSchema.migrations,
    this.directory,
  });

  final DatabaseFactory factory;
  final String name;
  final int schemaVersion;
  final List<SchemaMigration> migrations;
  final String? directory;

  Database? _db;

  Database get db {
    final Database? value = _db;
    if (value == null) {
      throw StateError('AppDatabase chưa được mở. Hãy gọi open() trước.');
    }
    return value;
  }

  bool get isOpen => _db != null;

  String get path {
    if (name == inMemoryDatabasePath || directory == null) return name;
    return p.join(directory!, name);
  }

  Future<Database> open({String? overridePath}) async {
    if (_db != null) return _db!;
    final String targetPath = overridePath ?? path;
    final Database opened = await factory.openDatabase(
      targetPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        singleInstance: false,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database db, int version) async {
          await _createSchema(db);
        },
        onUpgrade: (Database db, int from, int to) async {
          await _runMigrations(db, from, to);
        },
      ),
    );
    _db = opened;
    return opened;
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    for (final String statement in DbSchema.tables) {
      await db.execute(statement);
    }
    for (final String statement in DbSchema.indexes) {
      await db.execute(statement);
    }
  }

  Future<void> _runMigrations(DatabaseExecutor db, int from, int to) async {
    final List<SchemaMigration> sorted = List<SchemaMigration>.of(migrations)
      ..sort(
        (SchemaMigration a, SchemaMigration b) =>
            a.fromVersion.compareTo(b.fromVersion),
      );
    int cursor = from;
    for (final SchemaMigration migration in sorted) {
      if (migration.fromVersion != cursor) continue;
      if (migration.fromVersion < from || migration.toVersion > to) continue;
      await migration.upgrade(db);
      cursor = migration.toVersion;
    }
    if (cursor < to) {
      throw StateError('Thiếu migration từ $from đến $to (dừng ở $cursor).');
    }
  }

  Future<void> close() async {
    final Database? value = _db;
    _db = null;
    if (value != null && value.isOpen) {
      await value.close();
    }
  }

  Future<void> deleteDatabaseFile() async {
    await close();
    await factory.deleteDatabase(path);
  }

  static Future<void> runInTransaction(
    Database db,
    Future<void> Function(Transaction txn) action,
  ) {
    return db.transaction(action);
  }
}

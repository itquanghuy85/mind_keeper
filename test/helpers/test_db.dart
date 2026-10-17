import 'dart:io';

import 'package:mind_keeper/data/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initFfi() async {
  sqfliteFfiInit();
}

Future<AppDatabase> openMemoryDb() async {
  await initFfi();
  final AppDatabase app = AppDatabase(
    factory: databaseFactoryFfi,
    name: inMemoryDatabasePath,
  );
  await app.open();
  return app;
}

Future<({AppDatabase app, Directory dir})> openFileDb({
  String name = 'test.db',
}) async {
  await initFfi();
  final Directory dir = await Directory.systemTemp.createTemp('mindkeeper_test');
  final AppDatabase app = AppDatabase(
    factory: databaseFactoryFfi,
    name: name,
    directory: dir.path,
  );
  await app.open();
  return (app: app, dir: dir);
}

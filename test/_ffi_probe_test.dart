import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
void main() {
  test('ffi open', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE t(a INTEGER PRIMARY KEY)');
    await db.insert('t', {'a': 1});
    final rows = await db.query('t');
    expect(rows.length, 1);
    await db.close();
  });
}

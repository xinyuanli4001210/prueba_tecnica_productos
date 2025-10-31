import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static final LocalDb _instance = LocalDb._();
  LocalDb._();
  factory LocalDb() => _instance;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'products.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            synced INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
    return _db!;
  }

  // UPSERT (insert o reemplaza por id)
  Future<void> upsert(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(
      'products',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await database;
    return db.query('products', orderBy: 'name ASC');
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markSynced(String id, bool value) async {
    final db = await database;
    await db.update(
      'products',
      {'synced': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

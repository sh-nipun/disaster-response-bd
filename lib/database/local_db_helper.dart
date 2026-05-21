// pubspec.yaml e add korun: sqflite: ^2.3.3, path: ^1.9.0
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

class LocalDbHelper {
  // Singleton pattern - ekta instance e sob kaj hobe
  static final LocalDbHelper _instance = LocalDbHelper._internal();
  factory LocalDbHelper() => _instance;
  LocalDbHelper._internal();

  // Database? _database;

  // Future<Database> get database async {
  //   _database ??= await _initDB();
  //   return _database!;
  // }

  // Future<Database> _initDB() async {
  //   final dbPath = await getDatabasesPath();
  //   final path = join(dbPath, 'disaster_app.db');
  //   return await openDatabase(path, version: 1, onCreate: _createTables);
  // }

  // Future<void> _createTables(Database db, int version) async {
  //   await db.execute('''
  //     CREATE TABLE alerts (
  //       id TEXT PRIMARY KEY,
  //       title TEXT NOT NULL,
  //       description TEXT,
  //       type TEXT,
  //       severity TEXT,
  //       latitude REAL,
  //       longitude REAL,
  //       createdAt TEXT,
  //       isResolved INTEGER DEFAULT 0
  //     )
  //   ''');
  //   await db.execute('''
  //     CREATE TABLE users (
  //       id TEXT PRIMARY KEY,
  //       name TEXT,
  //       phone TEXT,
  //       email TEXT,
  //       role TEXT DEFAULT 'victim'
  //     )
  //   ''');
  // }

  // ============ ALERT OPERATIONS ============

  /// Notun alert save kora
  Future<void> insertAlert(Map<String, dynamic> alert) async {
    // final db = await database;
    // await db.insert('alerts', alert,
    //     conflictAlgorithm: ConflictAlgorithm.replace);
    print('[DB] Alert saved: ${alert['title']}');
  }

  /// Sob alert load kora
  Future<List<Map<String, dynamic>>> getAllAlerts() async {
    // final db = await database;
    // return await db.query('alerts', orderBy: 'createdAt DESC');
    return [];
  }

  /// Severity diye filter kora
  Future<List<Map<String, dynamic>>> getAlertsBySeverity(
      String severity) async {
    // final db = await database;
    // return await db.query('alerts',
    //     where: 'severity = ?', whereArgs: [severity]);
    return [];
  }

  /// Alert delete kora
  Future<void> deleteAlert(String id) async {
    // final db = await database;
    // await db.delete('alerts', where: 'id = ?', whereArgs: [id]);
    print('[DB] Alert deleted: $id');
  }

  /// Alert resolved mark kora
  Future<void> markAlertResolved(String id) async {
    // final db = await database;
    // await db.update('alerts', {'isResolved': 1},
    //     where: 'id = ?', whereArgs: [id]);
    print('[DB] Alert resolved: $id');
  }

  // ============ USER OPERATIONS ============

  /// User info save kora
  Future<void> saveUser(Map<String, dynamic> user) async {
    // final db = await database;
    // await db.insert('users', user,
    //     conflictAlgorithm: ConflictAlgorithm.replace);
    print('[DB] User saved: ${user['name']}');
  }

  /// User info load kora
  Future<Map<String, dynamic>?> getUser(String id) async {
    // final db = await database;
    // final results = await db.query('users',
    //     where: 'id = ?', whereArgs: [id], limit: 1);
    // return results.isNotEmpty ? results.first : null;
    return null;
  }
}

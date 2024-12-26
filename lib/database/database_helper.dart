import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:food_app/models/users.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database?> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'live-coding.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullname TEXT,
        email TEXT UNIQUE,
        password TEXT,
        height REAL,
        weight REAL
      )
      ''');
  }

  Future<void> insertStudent(Users users) async {
    final db = await database;
    await db!.insert(
      'users',
      users.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Users>> getStudent() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('users');

    return List.generate(maps.length, (i) {
      return Users(
          id: maps[i]['id'],
          fullname: maps[i]['fullname'],
          email: maps[i]['email'],
          password: maps[i]['password'],
          height: maps[i]['height'],
          weight: maps[i]['weight']);
    });
  }

  Future<bool> isTableEmpty() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db!.query('users');
    return result.isEmpty;
  }

  Future<bool> verifyUser(String email, String password) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db!.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    return result.isNotEmpty;
  }

  Future<Users?> getUserByLogin(String email, String password) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db!.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return Users(
        id: result[0]['id'],
        fullname: result[0]['fullname'],
        email: result[0]['email'],
        password: result[0]['password'],
        height: result[0]['height'],
        weight: result[0]['weight'],
      );
    }

    return null;
  }

  Future<void> updateHeight(String email, double newHeight) async {
    final db = await database;
    await db!.update(
      'users',
      {'height': newHeight},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> updateWeight(String email, double newWeight) async {
    final db = await database;
    await db!.update(
      'users',
      {'weight': newWeight},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db!.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<bool> doesEmailExist(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  Future<void> updatePassword(String email, String newPassword) async {
    final db = await database;
    await db!.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}

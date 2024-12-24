import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/users.dart';

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
        nom TEXT,
        prenom TEXT,
        email TEXT,
        telephone TEXT,
        password TEXT
      )
      ''');
  }

  Future<void> insertStudent(Users users) async {
    final db = await database;
    await db!.insert(
      'users',
      users.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Users>> getStudent() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('users');

    return List.generate(maps.length, (i) {
      return Users(
          id: maps[i]['id'],
          nom: maps[i]['nom'],
          prenom: maps[i]['prenom'],
          telephone: maps[i]['telephone'],
          email: maps[i]['email'],
          password: maps[i]['password']);
    });
  }

  Future<bool> isTableEmpty() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db!.query('users');
    return result.isEmpty;
  }

  Future<bool> verifyUser(String login, String password) async {
  final db = await database;
  final List<Map<String, dynamic>> result1 = await db!.query(
    'users',
    where: 'telephone = ? AND password = ?',
    whereArgs: [login, password],
  );
    final List<Map<String, dynamic>> result2 = await db.query(
    'users',
    where: 'email = ? AND password = ?',
    whereArgs: [login, password],
  );

  return result1.isNotEmpty || result2.isNotEmpty;
}

}

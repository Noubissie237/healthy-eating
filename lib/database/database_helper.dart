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
        password TEXT,
        taille REAL,
        poids REAL
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
          password: maps[i]['password'],
          taille: maps[i]['taille'],
          poids: maps[i]['poids']);
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

  Future<Users?> getUserByLogin(String login, String password) async {
    final db = await database;

    // Vérifier d'abord par téléphone
    final List<Map<String, dynamic>> result1 = await db!.query(
      'users',
      where: 'telephone = ? AND password = ?',
      whereArgs: [login, password],
    );

    // Puis par email
    final List<Map<String, dynamic>> result2 = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [login, password],
    );

    if (result1.isNotEmpty) {
      return Users(
        id: result1[0]['id'],
        nom: result1[0]['nom'],
        prenom: result1[0]['prenom'],
        telephone: result1[0]['telephone'],
        email: result1[0]['email'],
        password: result1[0]['password'],
        taille: result1[0]['taille'],
        poids: result1[0]['poids'],
      );
    } else if (result2.isNotEmpty) {
      return Users(
        id: result2[0]['id'],
        nom: result2[0]['nom'],
        prenom: result2[0]['prenom'],
        telephone: result2[0]['telephone'],
        email: result2[0]['email'],
        password: result2[0]['password'],
        taille: result2[0]['taille'],
        poids: result2[0]['poids'],
      );
    }

    return null;
  }
}

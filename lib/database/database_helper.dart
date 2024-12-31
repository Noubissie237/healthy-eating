import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:food_app/models/chat.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:food_app/models/users.dart';

class DatabaseHelper with ChangeNotifier {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

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

    // Table des conversations
    await db.execute('''
      CREATE TABLE conversations(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar_url TEXT,
        is_group INTEGER NOT NULL,
        participant_ids TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_message_at TEXT NOT NULL,
        last_message_content TEXT,
        last_message_type TEXT,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_muted INTEGER NOT NULL DEFAULT 0,
        unread_count INTEGER DEFAULT 0,
        last_message_sender TEXT
      )
    ''');

    // Table des messages
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        receiver_id TEXT,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        metadata TEXT,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        reply_to_message_id TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE meals(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        consumptionDateTime TEXT NOT NULL 
      )
    ''');

    // Index pour améliorer les performances
    await db.execute(
      'CREATE INDEX idx_messages_conversation_id ON messages(conversation_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_timestamp ON messages(timestamp)',
    );
  }

  Future<void> insertStudent(Users users) async {
    final db = await database;
    await db!.insert(
      'users',
      users.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Users>> getUsers() async {
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

  /*  Méthodes pour les messages */

  // Méthodes pour les conversations
  Future<void> insertConversation(Conversation conversation) async {
    final db = await database;
    await db!.insert(
      'conversations',
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Conversation>?> getConversations() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>>? maps = await db?.query(
        'conversations',
        orderBy: 'last_message_at DESC',
      );

      if (maps == null || maps.isEmpty) {
        return null; // Retourne null si aucune conversation n'est trouvée
      }

      return List.generate(maps.length, (i) => Conversation.fromMap(maps[i]));
    } catch (e) {
      // Gérer l'erreur (log, rethrow, etc.)
      print('Error fetching conversations: $e');
      return null; // Retourne null en cas d'erreur
    }
  }

  Future<void> updateConversation(Conversation conversation) async {
    final db = await database;
    await db!.update(
      'conversations',
      conversation.toMap(),
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<void> deleteConversation(String id) async {
    final db = await database;
    await db!.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes pour les messages
  Future<void> insertMessage(Message message) async {
    final db = await database;
    await db!.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => Message.fromMap(maps[i]));
  }

  Future<void> updateMessageStatus(
      String messageId, MessageStatus status) async {
    final db = await database;
    await db!.update(
      'messages',
      {'status': status.toString()},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> softDeleteMessage(String messageId) async {
    final db = await database;
    await db!.update(
      'messages',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteMessagesForConversation(String conversationId) async {
    final db = await database;
    await db!.delete(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<String?> findExistingConversationId(
      String user1Id, String user2Id) async {
    final db = await database;
    final conversations = await db!.query('conversations');

    for (var conv in conversations) {
      List<String> participants =
          List<String>.from(json.decode(conv['participant_ids'] as String));
      if (participants.contains(user1Id) && participants.contains(user2Id)) {
        return conv['id'] as String;
      }
    }
    return null;
  }
}

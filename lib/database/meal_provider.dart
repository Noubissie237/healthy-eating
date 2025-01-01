import 'package:flutter/material.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/models/meal.dart';
import 'package:sqflite/sqflite.dart';

class MealProvider with ChangeNotifier {
  List<Meal> _meals = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Meal> get meals => [..._meals.reversed];

  // Charger tous les repas
  Future<void> loadMeals() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db!.query('meals');
    _meals = maps.map((map) => Meal.fromMap(map)).toList();
    notifyListeners();
  }

  // Charger les repas d'un utilisateur spécifique
  Future<void> loadUserMeals(String userEmail) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'meals',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
    );
    _meals = maps.map((map) => Meal.fromMap(map)).toList();
    notifyListeners();
  }

  // Ajouter un repas
  Future<void> addMeal(Meal meal) async {
    final db = await _dbHelper.database;
    await db!.insert(
      'meals',
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadMeals();
  }

  // Mettre à jour un repas
  Future<void> updateMeal(Meal meal) async {
    final db = await _dbHelper.database;
    await db!.update(
      'meals',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
    await loadMeals();
  }

  // Supprimer un repas
  Future<void> deleteMeal(String id) async {
    final db = await _dbHelper.database;
    await db!.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadMeals();
  }

  // Obtenir le nombre total de repas pour un utilisateur
  Future<int> getUserMealsCount(String userEmail) async {
    final db = await _dbHelper.database;
    final result = Sqflite.firstIntValue(await db!.rawQuery(
      'SELECT COUNT(*) FROM meals WHERE userEmail = ?',
      [userEmail],
    ));
    return result ?? 0;
  }
}

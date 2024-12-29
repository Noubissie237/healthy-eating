import 'package:flutter/material.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/models/meal.dart';
import 'package:sqflite/sqflite.dart';

class MealProvider with ChangeNotifier {
  List<Meal> _meals = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Meal> get meals => [..._meals];

  Future<void> loadMeals() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db!.query('meals');
    _meals = maps.map((map) => Meal.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addMeal(Meal meal) async {
    final db = await _dbHelper.database;
    await db!.insert(
      'meals',
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadMeals();
  }

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

  Future<void> deleteMeal(String id) async {
    final db = await _dbHelper.database;
    await db!.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadMeals();
  }
}

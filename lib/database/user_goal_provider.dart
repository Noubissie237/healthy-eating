import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* Pour les objectifs de l'utilisateur */

class UserGoalProvider with ChangeNotifier {
  static const String _goalKey = 'user_goal';
  String _currentGoal = 'Stay Fit';

  UserGoalProvider() {
    _loadGoal();
  }

  String get currentGoal => _currentGoal;

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    _currentGoal = prefs.getString(_goalKey) ?? 'Stay Fit';
    notifyListeners();
  }

  Future<void> setGoal(String goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, goal);
    _currentGoal = goal;
    notifyListeners();
  }
}

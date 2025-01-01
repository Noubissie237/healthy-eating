import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:food_app/database/meal_provider.dart';
import 'package:food_app/database/user_goal_provider.dart';
import 'package:food_app/models/meal.dart';
import 'package:intl/intl.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late DateTime selectedDate;

  int getDailyCalorieGoal(String goal) {
    switch (goal) {
      case 'Weight Loss':
        return 1800; // Déficit calorique pour la perte de poids
      case 'Muscle Gain':
        return 2500; // Surplus calorique pour la prise de muscle
      case 'Stay Fit':
        return 2000; // Maintien du poids
      default:
        return 2000;
    }
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM dd, yyyy').format(selectedDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieAlert(String currentGoal) {
    final goalCalories = getDailyCalorieGoal(currentGoal);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\'ve exceeded your daily calorie goal of ${goalCalories}kcal',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(List<Meal> meals) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Daily Calories',
                  '${getDailyCalories(meals)} kcal',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Weekly Calories',
                  '${getWeeklyCalories(meals)} kcal',
                  Icons.view_week,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Monthly Calories',
                  '${getMonthlyCalories(meals)} kcal',
                  Icons.calendar_month,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Yearly Calories',
                  '${getYearlyCalories(meals)} kcal',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Average Weekly Calories',
            '${getAverageWeeklyCalories(meals).toStringAsFixed(1)} kcal',
            Icons.analytics,
            MyColors.secondaryColor,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeUserMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token != null && context.mounted) {
      final Map<String, dynamic> decodedToken = jsonDecode(token);
      final userEmail = decodedToken['email'];

      Provider.of<MealProvider>(context, listen: false)
          .loadUserMeals(userEmail);
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserMeals();
    });
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Calcul des vraies calories quotidiennes
  int getDailyCalories(List<Meal> meals) {
    return meals
        .where((meal) => isSameDay(meal.consumptionDateTime, selectedDate))
        .fold(0, (sum, meal) => sum + meal.calories);
  }

  // Calcul des calories hebdomadaires
  int getWeeklyCalories(List<Meal> meals) {
    final weekStart =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return meals
        .where((meal) =>
            meal.consumptionDateTime.isAfter(weekStart) &&
            meal.consumptionDateTime.isBefore(weekEnd))
        .fold(0, (sum, meal) => sum + meal.calories);
  }

  // Calcul des calories mensuelles
  int getMonthlyCalories(List<Meal> meals) {
    return meals
        .where((meal) =>
            meal.consumptionDateTime.month == selectedDate.month &&
            meal.consumptionDateTime.year == selectedDate.year)
        .fold(0, (sum, meal) => sum + meal.calories);
  }

  // Calcul des calories annuelles
  int getYearlyCalories(List<Meal> meals) {
    return meals
        .where((meal) => meal.consumptionDateTime.year == selectedDate.year)
        .fold(0, (sum, meal) => sum + meal.calories);
  }

  // Calcul de la moyenne hebdomadaire
  double getAverageWeeklyCalories(List<Meal> meals) {
    //final now = DateTime.now();
    //final startOfYear = DateTime(now.year);
    //final weeks = now.difference(startOfYear).inDays / 7;

    final totalCalories = getYearlyCalories(meals);
    // print(totalCalories);
    // print(weeks);
    // print(totalCalories / weeks);
    // return totalCalories / weeks;
    return totalCalories / 7;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MealProvider, UserGoalProvider>(
        builder: (context, mealProvider, goalProvider, child) {
      final meals = mealProvider.meals;
      final dailyCalories = getDailyCalories(meals);

      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'My Statistics',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalSection(),
              const SizedBox(height: 20),
              _buildDateSelector(),
              const SizedBox(height: 20),
              if (dailyCalories > getDailyCalorieGoal(goalProvider.currentGoal))
                _buildCalorieAlert(goalProvider.currentGoal),
              _buildStatisticsCards(meals),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildGoalSection() {
    return Consumer<UserGoalProvider>(builder: (context, goalProvider, child) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Goal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.help_outline,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Daily Calorie Goals'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildGoalInfo(
                                'Stay Fit',
                                '2000 calories/day',
                                'Maintain your current weight',
                                Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _buildGoalInfo(
                                'Weight Loss',
                                '1800 calories/day',
                                'Caloric deficit for weight loss',
                                Colors.red,
                              ),
                              const SizedBox(height: 12),
                              _buildGoalInfo(
                                'Muscle Gain',
                                '2500 calories/day',
                                'Caloric surplus for muscle growth',
                                Colors.blue,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Close'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildGoalOption(
                  context,
                  goalProvider,
                  'Weight Loss',
                  Icons.trending_down,
                  Colors.red,
                ),
                const SizedBox(width: 12),
                _buildGoalOption(
                  context,
                  goalProvider,
                  'Muscle Gain',
                  Icons.fitness_center,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildGoalOption(
                  context,
                  goalProvider,
                  'Stay Fit',
                  Icons.favorite,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGoalInfo(
      String goal, String calories, String description, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                calories,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalOption(
    BuildContext context,
    UserGoalProvider goalProvider,
    String goal,
    IconData icon,
    Color color,
  ) {
    final isSelected = goalProvider.currentGoal == goal;
    return Expanded(
      child: GestureDetector(
        onTap: () => goalProvider.setGoal(goal),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                goal,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

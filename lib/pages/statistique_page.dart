import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:food_app/colors/my_colors.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String selectedGoal = 'Stay Fit';
  final Random random = Random();
  final dailyCalorieGoal = 2000; // Exemple de valeur
  DateTime selectedDate = DateTime.now();

  // Simuler des données aléatoires pour les statistiques
  int getDailyCalories() => random.nextInt(2500) + 500;
  int getWeeklyCalories() => random.nextInt(15000) + 5000;
  int getMonthlyCalories() => random.nextInt(60000) + 20000;
  int getYearlyCalories() => random.nextInt(700000) + 200000;
  double getAverageWeeklyCalories() => (random.nextInt(2000) + 1500).toDouble();

  @override
  Widget build(BuildContext context) {
    final dailyCalories = getDailyCalories();

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
            if (dailyCalories > dailyCalorieGoal) _buildCalorieAlert(),
            _buildStatisticsCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSection() {
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
          const Text(
            'Your Goal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildGoalOption(
                'Weight Loss',
                Icons.trending_down,
                Colors.red,
              ),
              const SizedBox(width: 12),
              _buildGoalOption(
                'Muscle Gain',
                Icons.fitness_center,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildGoalOption(
                'Stay Fit',
                Icons.favorite,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String goal, IconData icon, Color color) {
    final isSelected = selectedGoal == goal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGoal = goal),
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

  Widget _buildCalorieAlert() {
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
              'You\'ve exceeded your daily calorie goal of ${dailyCalorieGoal}kcal',
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

  Widget _buildStatisticsCards() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Daily Calories',
                  '${getDailyCalories()} kcal',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Weekly Calories',
                  '${getWeeklyCalories()} kcal',
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
                  '${getMonthlyCalories()} kcal',
                  Icons.calendar_month,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Yearly Calories',
                  '${getYearlyCalories()} kcal',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Average Weekly Calories',
            '${getAverageWeeklyCalories().toStringAsFixed(1)} kcal',
            Icons.analytics,
            MyColors.primaryColor,
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
}

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/models/meal.dart';
import 'package:food_app/database/meal_provider.dart';
import 'package:food_app/database/user_goal_provider.dart';
import 'package:provider/provider.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  List<Meal> _recommendedMeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    await Future.delayed(
        const Duration(milliseconds: 500)); // Pour une meilleure UX

    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final goalProvider = Provider.of<UserGoalProvider>(context, listen: false);

    // Obtenir le seuil calorique en fonction de l'objectif
    final calorieGoal = _getDailyCalorieGoal(goalProvider.currentGoal);

    // Calculer les calories déjà consommées aujourd'hui
    final todayMeals = mealProvider.meals
        .where((meal) => _isSameDay(meal.consumptionDateTime, DateTime.now()))
        .toList();
    final consumedCalories =
        todayMeals.fold(0, (sum, meal) => sum + meal.calories);

    // Calories restantes disponibles
    final remainingCalories = calorieGoal - consumedCalories;

    // Obtenir tous les repas uniques de la base de données (pour les suggestions)
    final uniqueMeals = _getUniqueMeals(mealProvider.meals);

    // Générer les recommandations avec l'algorithme du sac à dos
    _recommendedMeals = _knapsackRecommendation(
      uniqueMeals,
      remainingCalories,
      maxItems: 3, // Limiter à 3 suggestions
    );

    setState(() => _isLoading = false);
  }

  int _getDailyCalorieGoal(String goal) {
    switch (goal) {
      case 'Weight Loss':
        return 1800;
      case 'Muscle Gain':
        return 2500;
      case 'Stay Fit':
        return 2000;
      default:
        return 2000;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  List<Meal> _getUniqueMeals(List<Meal> meals) {
    final uniqueMeals = <String, Meal>{};
    for (var meal in meals) {
      if (!uniqueMeals.containsKey(meal.name)) {
        uniqueMeals[meal.name] = meal;
      }
    }
    return uniqueMeals.values.toList();
  }

  List<Meal> _knapsackRecommendation(
    List<Meal> meals,
    int remainingCalories, {
    int maxItems = 3,
  }) {
    if (meals.isEmpty || remainingCalories <= 0) return [];

    // Création de la matrice pour la programmation dynamique
    final n = meals.length;
    final dp = List.generate(
      n + 1,
      (_) => List.generate(remainingCalories + 1, (_) => 0),
    );
    final keep = List.generate(
      n + 1,
      (_) => List.generate(remainingCalories + 1, (_) => false),
    );

    // Remplir la matrice
    for (var i = 1; i <= n; i++) {
      for (var w = 0; w <= remainingCalories; w++) {
        if (meals[i - 1].calories <= w) {
          final include =
              meals[i - 1].calories + dp[i - 1][w - meals[i - 1].calories];
          final exclude = dp[i - 1][w];

          if (include > exclude) {
            dp[i][w] = include;
            keep[i][w] = true;
          } else {
            dp[i][w] = exclude;
          }
        } else {
          dp[i][w] = dp[i - 1][w];
        }
      }
    }

    // Récupérer les repas sélectionnés
    final selected = <Meal>[];
    var w = remainingCalories;
    for (var i = n; i > 0 && selected.length < maxItems; i--) {
      if (keep[i][w]) {
        selected.add(meals[i - 1]);
        w -= meals[i - 1].calories;
      }
    }

    return selected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Meal Recommendations',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: Consumer2<MealProvider, UserGoalProvider>(
        builder: (context, mealProvider, goalProvider, _) {
          final todayMeals = mealProvider.meals
              .where((meal) =>
                  _isSameDay(meal.consumptionDateTime, DateTime.now()))
              .toList();
          final consumedCalories =
              todayMeals.fold(0, (sum, meal) => sum + meal.calories);
          final goalCalories = _getDailyCalorieGoal(goalProvider.currentGoal);
          final remainingCalories = goalCalories - consumedCalories;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalorieOverview(consumedCalories, goalCalories),
                if (_isLoading)
                  _buildLoadingIndicator()
                else if (_recommendedMeals.isEmpty)
                  _buildNoRecommendations()
                else
                  _buildRecommendationsList(remainingCalories),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalorieOverview(int consumed, int goal) {
    final progress = (consumed / goal).clamp(0.0, 1.0);
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
                'Today\'s Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$consumed / $goal kcal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.red : MyColors.primaryColor,
              ),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Finding the best meal combinations for you...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecommendations() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_meals,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recommendations available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adding more meals to your history to get personalized recommendations.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(int remainingCalories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Recommended Meals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recommendedMeals.length,
          itemBuilder: (context, index) {
            final meal = _recommendedMeals[index];
            return _buildMealCard(meal, remainingCalories);
          },
        ),
      ],
    );
  }

  Widget _buildMealCard(Meal meal, int remainingCalories) {
    final caloriePercentage = (meal.calories / remainingCalories * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Implémenter l'ajout du repas
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: MyColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: MyColors.primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meal.calories} kcal - $caloriePercentage% of remaining',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.add_circle_outline,
                  color: MyColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/meal_provider.dart';
import 'package:food_app/models/meal.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ListMealsPage extends StatefulWidget {
  const ListMealsPage({super.key});

  @override
  State<StatefulWidget> createState() => _ListMealsPage();
}

class _ListMealsPage extends State<ListMealsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MealProvider>(context, listen: false).loadMeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'All Meals',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Consumer<MealProvider>(
        builder: (context, mealProvider, child) {
          final meals = mealProvider.meals;

          if (meals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun repas ajouté pour le moment',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez par ajouter votre premier repas !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showMealDialog(context, meal),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar élégant
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    MyColors.secondaryColor.withOpacity(0.7),
                                    MyColors.secondaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  meal.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Informations du repas
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_fire_department,
                                        size: 16,
                                        color: MyColors.failed,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${meal.calories} calories',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy at HH:mm')
                                            .format(meal.consumptionDateTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Actions
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: MyColors.secondaryColor,
                                  onPressed: () =>
                                      _showMealDialog(context, meal),
                                  tooltip: 'Update',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: MyColors.failed,
                                  onPressed: () =>
                                      _confirmDelete(context, meal),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMealDialog(context),
        backgroundColor: MyColors.secondaryColor,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add a meal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Dialog d'ajout/modification amélioré
  Future<void> _showMealDialog(BuildContext context, [Meal? meal]) async {
    final nameController = TextEditingController(text: meal?.name);
    final caloriesController = TextEditingController(
      text: meal?.calories.toString(),
    );
    DateTime selectedDateTime = meal?.consumptionDateTime ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        title: Row(
          children: [
            Icon(
              meal == null ? Icons.add_circle : Icons.edit,
              color: MyColors.secondaryColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              meal == null ? 'Add a meal' : 'Update meal',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Meal\'s name',
                  hintText: 'Enter the meal\'s name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: MyColors.secondaryColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: MyColors.secondaryColor, width: 2),
                  ),
                  prefixIcon:
                      Icon(Icons.restaurant_menu, color: MyColors.secondaryColor),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: caloriesController,
                decoration: InputDecoration(
                  labelText: 'Calories',
                  hintText: 'Enter the calories\'s number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: MyColors.secondaryColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: MyColors.secondaryColor, width: 2),
                  ),
                  prefixIcon:
                      Icon(Icons.local_fire_department, color: MyColors.failed),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: MyColors.secondaryColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2025),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: MyColors.secondaryColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: MyColors.secondaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: MyColors.secondaryColor),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date and Time',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy at HH:mm')
                                    .format(selectedDateTime),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final calories =
                  int.tryParse(caloriesController.text.trim()) ?? 0;

              if (name.isEmpty || calories <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill in all fields correctly.',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              final newMeal = Meal(
                id: meal?.id,
                name: name,
                calories: calories,
                consumptionDateTime: selectedDateTime,
              );

              final provider = context.read<MealProvider>();
              if (meal == null) {
                provider.addMeal(newMeal);
              } else {
                provider.updateMeal(newMeal);
              }

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              meal == null ? 'Add' : 'Update',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              'Confirm deletion',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${meal.name} ?',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.failed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        context.read<MealProvider>().deleteMeal(meal.id);

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'The meal ${meal.name} was deleted',
              style: const TextStyle(color: Colors.white),
            ),
            //backgroundColor: MyColors.secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }
}

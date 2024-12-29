import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/meal_provider.dart';
import 'package:food_app/models/meal.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ListMealsPage extends StatefulWidget {
  const ListMealsPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ListMealsPage();
  }
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
      body: Consumer<MealProvider>(
        builder: (context, mealProvider, child) {
          final meals = mealProvider.meals;

          return meals.isEmpty
              ? Center(
                  child: Text(
                    'Aucun repas ajouté pour le moment',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Theme.of(context).primaryColorLight,
                          child: Text(
                            meal.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorDark,
                            ),
                          ),
                        ),
                        title: Text(
                          meal.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${meal.calories} calories\n${DateFormat('dd/MM/yyyy à HH:mm').format(meal.consumptionDateTime)}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blueAccent),
                              tooltip: 'Modifier le repas',
                              onPressed: () => _showMealDialog(context, meal),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: 'Supprimer le repas',
                              onPressed: () => _confirmDelete(context, meal),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showMealDialog(context),
      ),
    );
  }

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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        title: Text(
          meal == null ? 'Ajouter un repas' : 'Modifier le repas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nom du repas
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du repas',
                  hintText: 'Entrez le nom du repas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.fastfood, color: MyColors.green),
                ),
              ),
              const SizedBox(height: 16),
              // Calories
              TextField(
                controller: caloriesController,
                decoration: InputDecoration(
                  labelText: 'Calories',
                  hintText: 'Entrez le nombre de calories',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon:
                      Icon(Icons.local_fire_department, color: MyColors.failed),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Sélection de la date et de l'heure
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: BorderSide(
                      color: Theme.of(context).primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2025),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (pickedTime != null) {
                      selectedDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    }
                  }
                },
                icon: Icon(Icons.calendar_today,
                    color: Theme.of(context).primaryColor),
                label: Text(
                  'Sélectionner date et heure',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Date sélectionnée : ${selectedDateTime.toLocal().toString().split(' ')[0]} à '
                '${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          // Bouton Annuler
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.red)),
          ),
          // Bouton Ajouter / Modifier
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final calories =
                  int.tryParse(caloriesController.text.trim()) ?? 0;

              if (name.isEmpty || calories <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Veuillez remplir correctement tous les champs.',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            child: Text(
              meal == null ? 'Ajouter' : 'Modifier',
              style: TextStyle(fontSize: 16),
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
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${meal.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: MyColors.backgroundColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<MealProvider>().deleteMeal(meal.id);
    }
  }
}

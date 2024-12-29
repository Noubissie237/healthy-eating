import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/meal_provider.dart';
import 'package:food_app/models/meal.dart';
//import 'package:food_app/database/database_helper.dart';
//import 'package:food_app/models/users.dart';
import 'package:food_app/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePage();
  }
}

class _HomePage extends State<HomePage> {
  File? _imageFile;
  String? _audioPath;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MealProvider>(context, listen: false).loadMeals();
    });
  }

  Future<void> _handlePickImage() async {
    File? image = await pickImage();
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
      print("Chemin de l'image : ${image.path} - image : $_imageFile");
    }
  }

  Future<void> _handleRecordAudio() async {
    if (_isRecording) {
      String? path = await stopRecording();
      if (path != null) {
        setState(() {
          _audioPath = path;
          print("$_audioPath");
          _isRecording = false;
        });
        print("Enregistrement terminé : $path");
      }
    } else {
      try {
        await startRecording();
        setState(() {
          _isRecording = true;
        });
        print("Enregistrement en cours...");
      } catch (e) {
        print("Erreur lors de l'enregistrement : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBar(
        elevation: 8,
        title: Image.asset('assets/images/logo.png', width: 100),
        actions: [
          IconButton(
            onPressed: _handlePickImage,
            icon: const Icon(Icons.camera_alt, color: MyColors.textColor),
          ),
          IconButton(
            onPressed: _handleRecordAudio,
            icon: Icon(_isRecording ? Icons.mic_off : Icons.mic,
                color: MyColors.textColor),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/recordings');
            },
            icon: const Icon(Icons.chat, color: MyColors.textColor),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signup');
            },
            icon: const Icon(Icons.person_add_alt_rounded,
                color: MyColors.textColor),
          ),
        ],
      ),
      body: Consumer<MealProvider>(
        builder: (context, mealProvider, child) {
          final meals = mealProvider.meals;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    meal.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${meal.calories} calories\n${DateFormat('dd/MM/yyyy HH:mm').format(meal.consumptionDateTime)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showMealDialog(context, meal),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
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
        title: Text(meal == null ? 'Ajouter un repas' : 'Modifier le repas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du repas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDateTime,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2025),
                );
                if (picked != null) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                  );
                  if (pickedTime != null) {
                    selectedDateTime = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  }
                }
              },
              child: const Text('Sélectionner date et heure'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              final calories = int.tryParse(caloriesController.text) ?? 0;

              if (name.isNotEmpty && calories > 0) {
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
              }
            },
            child: Text(meal == null ? 'Ajouter' : 'Modifier'),
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<MealProvider>().deleteMeal(meal.id);
    }
  }
}

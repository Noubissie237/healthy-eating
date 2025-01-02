import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/meal_provider.dart';
import 'package:food_app/models/meal.dart';
import 'package:food_app/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum pour le tri
enum SortOption {
  dateAsc,
  dateDesc,
  caloriesAsc,
  caloriesDesc,
}

class ListMealsPage extends StatefulWidget {
  const ListMealsPage({super.key});

  @override
  State<StatefulWidget> createState() => _ListMealsPage();
}

Future<void> _initializeUserMeals(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('user_token');

  if (token != null && context.mounted) {
    final Map<String, dynamic> decodedToken = jsonDecode(token);
    final userEmail = decodedToken['email'];

    Provider.of<MealProvider>(context, listen: false).loadUserMeals(userEmail);
  }
}

class _ListMealsPage extends State<ListMealsPage> {
  // États pour le filtrage et le tri
  DateTime? _selectedDate;
  double? _minCalories;
  double? _maxCalories;
  SortOption _currentSort = SortOption.dateDesc;

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserMeals(context);
    });

    // Ajouter un listener au searchController
    _searchController.addListener(() {
      _searchNotifier.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchNotifier.dispose();
    super.dispose();
  }

  // Fonction pour filtrer les repas
  List<Meal> _filterMeals(List<Meal> meals, String searchQuery) {
    return meals.where((meal) {
      // Filtre par date
      if (_selectedDate != null) {
        final isSameDay =
            meal.consumptionDateTime.year == _selectedDate!.year &&
                meal.consumptionDateTime.month == _selectedDate!.month &&
                meal.consumptionDateTime.day == _selectedDate!.day;
        if (!isSameDay) return false;
      }

      // Filtre par recherche
      if (searchQuery.isNotEmpty) {
        if (!meal.name.toLowerCase().contains(searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Filtre par calories
      if (_minCalories != null && meal.calories < _minCalories!) return false;
      if (_maxCalories != null && meal.calories > _maxCalories!) return false;

      return true;
    }).toList();
  }

  // Fonction pour trier les repas
  List<Meal> _sortMeals(List<Meal> meals) {
    switch (_currentSort) {
      case SortOption.dateAsc:
        return meals
          ..sort(
              (a, b) => a.consumptionDateTime.compareTo(b.consumptionDateTime));
      case SortOption.dateDesc:
        return meals
          ..sort(
              (a, b) => b.consumptionDateTime.compareTo(a.consumptionDateTime));
      case SortOption.caloriesAsc:
        return meals..sort((a, b) => a.calories.compareTo(b.calories));
      case SortOption.caloriesDesc:
        return meals..sort((a, b) => b.calories.compareTo(a.calories));
    }
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search meals...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filtre par date
                FilterChip(
                  label: Text(_selectedDate == null
                      ? 'Select Date'
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                  selected: _selectedDate != null,
                  onSelected: (_) async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  deleteIcon: _selectedDate != null
                      ? const Icon(Icons.close, size: 18)
                      : null,
                  onDeleted: _selectedDate != null
                      ? () {
                          setState(() {
                            _selectedDate = null;
                          });
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                // Options de tri
                DropdownButton<SortOption>(
                  value: _currentSort,
                  items: const [
                    DropdownMenuItem(
                      value: SortOption.dateDesc,
                      child: Text('Latest first'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.dateAsc,
                      child: Text('Oldest first'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.caloriesDesc,
                      child: Text('Highest calories'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.caloriesAsc,
                      child: Text('Lowest calories'),
                    ),
                  ],
                  onChanged: (SortOption? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentSort = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Filtre de calories
                ActionChip(
                  label: const Text('Calories Range'),
                  onPressed: () {
                    _showCaloriesFilterDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCaloriesFilterDialog() async {
    double? tempMinCalories = _minCalories;
    double? tempMaxCalories = _maxCalories;
    final minController =
        TextEditingController(text: tempMinCalories?.toString() ?? '');
    final maxController =
        TextEditingController(text: tempMaxCalories?.toString() ?? '');
    bool hasError = false;

    // Fonction de validation
    bool _validateInputs(String? min, String? max) {
      if (min != null && max != null && min.isNotEmpty && max.isNotEmpty) {
        final minVal = double.tryParse(min);
        final maxVal = double.tryParse(max);
        if (minVal != null && maxVal != null && minVal > maxVal) {
          return false;
        }
      }
      return true;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: MyColors.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter by Calories',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set your calorie range',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: minController,
                      decoration: InputDecoration(
                        labelText: 'Minimum Calories',
                        hintText: 'Enter minimum calories',
                        prefixIcon: const Icon(Icons.remove_circle_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: MyColors.primaryColor,
                            width: 2,
                          ),
                        ),
                        errorText: hasError ? 'Invalid range' : null,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() {
                          tempMinCalories = double.tryParse(value);
                          hasError = !_validateInputs(
                              minController.text, maxController.text);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: maxController,
                      decoration: InputDecoration(
                        labelText: 'Maximum Calories',
                        hintText: 'Enter maximum calories',
                        prefixIcon: const Icon(Icons.add_circle_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: MyColors.primaryColor,
                            width: 2,
                          ),
                        ),
                        errorText: hasError ? 'Invalid range' : null,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() {
                          tempMaxCalories = double.tryParse(value);
                          hasError = !_validateInputs(
                              minController.text, maxController.text);
                        });
                      },
                    ),
                    if (hasError) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Maximum calories must be greater than minimum calories',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      minController.clear();
                      maxController.clear();
                      tempMinCalories = null;
                      tempMaxCalories = null;
                      hasError = false;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: hasError
                      ? null
                      : () {
                          if (_validateInputs(
                              minController.text, maxController.text)) {
                            this.setState(() {
                              _minCalories = tempMinCalories;
                              _maxCalories = tempMaxCalories;
                            });
                            Navigator.pop(context);

                            // Afficher un message de confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Calories filter applied: ${tempMinCalories?.toStringAsFixed(0) ?? '0'} - ${tempMaxCalories?.toStringAsFixed(0) ?? '∞'} kcal',
                                    ),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: 'OK',
                                  textColor: Colors.white,
                                  onPressed: () {},
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text(
                    'Apply',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text("Data loading error"),
          );
        }

        final userInfo = snapshot.data!;

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
              return Column(
                children: [
                  _buildFilterBar(),
                  ValueListenableBuilder<String>(
                    valueListenable: _searchNotifier,
                    builder: (context, searchQuery, _) {
                      // Appliquer les filtres et le tri
                      List<Meal> filteredAndSortedMeals =
                          _filterMeals(mealProvider.meals, searchQuery);
                      filteredAndSortedMeals =
                          _sortMeals(filteredAndSortedMeals);

                      if (filteredAndSortedMeals.isEmpty &&
                          mealProvider.meals.isNotEmpty) {
                        return const Expanded(
                          child: Center(
                            child: Text(
                              'No meals match your filters',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      } else if (mealProvider.meals.isEmpty) {
                        return Expanded(
                          child: Center(
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
                                  'No meals added at this time',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start by adding your first meal !',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredAndSortedMeals.length,
                          itemBuilder: (context, index) {
                            final meal = filteredAndSortedMeals[index];
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
                                    onTap: () => _showMealDialog(
                                        context, userInfo['email']!, meal),
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
                                                  MyColors.primaryColor
                                                      .withOpacity(0.7),
                                                  MyColors.primaryColor,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                      Icons
                                                          .local_fire_department,
                                                      size: 16,
                                                      color: MyColors.failed,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${meal.calories} calories',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                                      DateFormat(
                                                              'dd/MM/yyyy - HH:mm')
                                                          .format(meal
                                                              .consumptionDateTime),
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
                                                color: MyColors.primaryColor,
                                                onPressed: () =>
                                                    _showMealDialog(
                                                        context,
                                                        userInfo['email']!,
                                                        meal),
                                                tooltip: 'Update',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                color: MyColors.failed,
                                                onPressed: () => _confirmDelete(
                                                    context, meal),
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
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showMealDialog(context, userInfo['email']!),
            backgroundColor: MyColors.primaryColor,
            icon: const Icon(Icons.add),
            label: const Text(
              'Add a meal',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  // Dialog d'ajout/modification amélioré
  Future<void> _showMealDialog(BuildContext context, String userEmail,
      [Meal? meal]) async {
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
              color: MyColors.primaryColor,
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
                    borderSide:
                        BorderSide(color: MyColors.primaryColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        BorderSide(color: MyColors.primaryColor, width: 2),
                  ),
                  prefixIcon:
                      Icon(Icons.restaurant_menu, color: MyColors.primaryColor),
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
                    borderSide:
                        BorderSide(color: MyColors.primaryColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        BorderSide(color: MyColors.primaryColor, width: 2),
                  ),
                  prefixIcon:
                      Icon(Icons.local_fire_department, color: MyColors.failed),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: MyColors.primaryColor, width: 2),
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
                        lastDate: DateTime(2026),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: MyColors.primaryColor,
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
                                  primary: MyColors.primaryColor,
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
                          Icon(Icons.calendar_today,
                              color: MyColors.primaryColor),
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
                                DateFormat('dd/MM/yyyy - HH:mm')
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
                  userEmail: userEmail);

              final provider = context.read<MealProvider>();
              if (meal == null) {
                provider.addMeal(newMeal);
              } else {
                provider.updateMeal(newMeal);
              }

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primaryColor,
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
            //backgroundColor: MyColors.primaryColor,
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

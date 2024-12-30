import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/meal_provider.dart';
import 'package:food_app/models/meal.dart';
import 'package:food_app/pages/list_meals_page.dart';
import 'package:food_app/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isWeight = false;
  bool _isHeight = false;

  @override
  void initState() {
    super.initState();
    _initializeValues();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MealProvider>(context, listen: false).loadMeals();
    });
  }

  Future<void> _initializeValues() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token != null) {
      final Map<String, dynamic> decodedToken = jsonDecode(token);
      final height = decodedToken['height']?.toString() ?? 'Unknown';
      final weight = decodedToken['weight']?.toString() ?? 'Unknown';

      setState(() {
        _isHeight = height != 'Unknown';
        _isWeight = weight != 'Unknown';
      });
    }
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
    return (_isHeight && _isWeight)
        ? FutureBuilder<Map<String, String>>(
            future: _getUserInfo(),
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
              final bmi = calculerIMC(
                double.parse(userInfo['weight']!),
                double.parse(userInfo['height']!),
              );

              // if (userInfo['height'] != 'Unknown') {
              //   _isHeight = true;
              // } else {
              //   _isHeight = false;
              // }

              // if (userInfo['weight'] != 'Unknown') {
              //   _isWeight = true;
              // } else {
              //   _isWeight = false;
              // }

              return Scaffold(
                appBar: AppBar(
                  backgroundColor: const Color.fromARGB(87, 3, 218, 197),
                  title: Image.asset('assets/images/logo.png', width: 100),
                  actions: [
                    IconButton(
                      onPressed: _handlePickImage,
                      icon: const Icon(Icons.camera_alt,
                          color: MyColors.textColor),
                    ),
                    IconButton(
                      onPressed: _handleRecordAudio,
                      icon: Icon(
                        _isRecording ? Icons.mic_off : Icons.mic,
                        color: MyColors.textColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/recordings'),
                      icon: const Icon(Icons.chat, color: MyColors.textColor),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      icon: const Icon(
                        Icons.person_add_alt_rounded,
                        color: MyColors.textColor,
                      ),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // Greeting Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromRGBO(158, 158, 158, 0.1),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "Hi, ${userInfo['fullname'].toString().split(' ').last.substring(0, 1).toUpperCase()}${userInfo['fullname'].toString().split(' ').last.substring(1).toLowerCase()} 😊",
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.06,
                                    color: MyColors.textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Metrics Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromRGBO(158, 158, 158, 0.1),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildMetricColumn(
                                      context,
                                      "Weight",
                                      "${userInfo['weight']} Kg",
                                      Icons.monitor_weight_outlined,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 50,
                                      color: const Color.fromRGBO(
                                          158, 158, 158, 0.3),
                                    ),
                                    _buildMetricColumn(
                                      context,
                                      "Height",
                                      "${userInfo['height']} Cm",
                                      Icons.height,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // BMI Results Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromRGBO(
                                          158, 158, 158, 0.1),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "Your BMI",
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                        color: MyColors.secondaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      bmi.toStringAsFixed(2),
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.08,
                                        color: MyColors.textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            3, 218, 198, 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        interpreterIMC(bmi),
                                        style: const TextStyle(
                                          color: MyColors.secondaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      recommandationIMC(bmi),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            const Color.fromRGBO(0, 0, 0, 0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Meals Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(158, 158, 158, 0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        "Recent meals",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Scaffold(
                        backgroundColor: MyColors.backgroundColor,
                        body: Consumer<MealProvider>(
                          builder: (context, mealProvider, child) {
                            final meals = mealProvider.meals;

                            return meals.isEmpty
                                ? Center(
                                    child: Text(
                                      'No meals added at this time',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          itemCount: 3,
                                          itemBuilder: (context, index) {
                                            final meal = meals[index];
                                            final isLastItem = index == 3 - 1;

                                            return Column(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        spreadRadius: 2,
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () =>
                                                            _showMealDialog(
                                                                context, meal),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 60,
                                                                height: 60,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  gradient:
                                                                      LinearGradient(
                                                                    colors: [
                                                                      const Color
                                                                          .fromRGBO(
                                                                          3,
                                                                          218,
                                                                          198,
                                                                          0.7),
                                                                      MyColors
                                                                          .secondaryColor,
                                                                    ],
                                                                    begin: Alignment
                                                                        .topLeft,
                                                                    end: Alignment
                                                                        .bottomRight,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    meal.name[0]
                                                                        .toUpperCase(),
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          24,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 16),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      meal.name,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            4),
                                                                    Text(
                                                                      '${meal.calories} calories',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .grey[600],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            2),
                                                                    Text(
                                                                      DateFormat(
                                                                              'dd/MM/yyyy at HH:mm')
                                                                          .format(
                                                                              meal.consumptionDateTime),
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .grey[500],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .edit),
                                                                    color: Theme.of(
                                                                            context)
                                                                        .primaryColor,
                                                                    onPressed: () =>
                                                                        _showMealDialog(
                                                                            context,
                                                                            meal),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .delete),
                                                                    color: Colors
                                                                        .redAccent,
                                                                    onPressed: () =>
                                                                        _confirmDelete(
                                                                            context,
                                                                            meal),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (isLastItem &&
                                                    meals.length > 3)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 16, bottom: 8),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                const ListMealsPage(),
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Color.fromRGBO(3,
                                                                218, 198, 0.7),
                                                        minimumSize: const Size(
                                                            double.infinity,
                                                            50),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            'Voir plus',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Icon(
                                                              Icons
                                                                  .arrow_forward,
                                                              color:
                                                                  Colors.white),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (!isLastItem)
                                                  const SizedBox(height: 16),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                          },
                        ),
                        floatingActionButton: FloatingActionButton(
                          backgroundColor: MyColors.secondaryColor,
                          child: const Icon(Icons.add),
                          onPressed: () => _showMealDialog(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        : FutureBuilder<Map<String, String>>(
            future: _getUserInfo(),
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
                appBar: AppBar(
                  backgroundColor: const Color.fromARGB(87, 3, 218, 197),
                  title: Image.asset('assets/images/logo.png', width: 100),
                  actions: [
                    IconButton(
                      onPressed: _handlePickImage,
                      icon: const Icon(Icons.camera_alt,
                          color: MyColors.textColor),
                    ),
                    IconButton(
                      onPressed: _handleRecordAudio,
                      icon: Icon(
                        _isRecording ? Icons.mic_off : Icons.mic,
                        color: MyColors.textColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/recordings'),
                      icon: const Icon(Icons.chat, color: MyColors.textColor),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      icon: const Icon(
                        Icons.person_add_alt_rounded,
                        color: MyColors.textColor,
                      ),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                // Greeting Card - Inchangé
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color.fromRGBO(158, 158, 158, 0.1),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "Hi, ${userInfo['fullname'].toString().split(' ').last.substring(0, 1).toUpperCase()}${userInfo['fullname'].toString().split(' ').last.substring(1).toLowerCase()} 😊",
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.06,
                                      color: MyColors.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // Info Card
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromRGBO(3, 218, 198, 0.1),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: const Color.fromRGBO(
                                          3, 218, 198, 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: MyColors.secondaryColor,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              "To personalize your tracking and help you achieve your goals, we invite you to enter your weight and height.",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: MyColors.textColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "This information will allow us to offer you recommendations tailored to your profile. It's quick and easy! Ready to start your journey to better health?",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: const Color.fromRGBO(
                                              0, 0, 0, 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Action Card
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromRGBO(
                                            158, 158, 158, 0.08),
                                        spreadRadius: 2,
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        "To fill in your weight and height: ",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: MyColors.textColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 15),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              158, 158, 158, 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.settings,
                                              size: 20,
                                              color: const Color.fromRGBO(
                                                  0, 0, 0, 0.7),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              "Settings > My informations",
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Or click",
                                            style: TextStyle(
                                              color: const Color.fromRGBO(
                                                  0, 0, 0, 0.8),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                  context, '/account');
                                            },
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              backgroundColor:
                                                  const Color.fromRGBO(
                                                      3, 218, 198, 0.1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  "here",
                                                  style: TextStyle(
                                                    color:
                                                        MyColors.secondaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  size: 16,
                                                  color:
                                                      MyColors.secondaryColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )),
                      ),
                    ),

                    // Meals Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(158, 158, 158, 0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        "Recent meals",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Scaffold(
                        backgroundColor: MyColors.backgroundColor,
                        body: Consumer<MealProvider>(
                          builder: (context, mealProvider, child) {
                            final meals = mealProvider.meals;

                            return meals.isEmpty
                                ? Center(
                                    child: Text(
                                      'No meals added at this time',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          itemCount: 3,
                                          itemBuilder: (context, index) {
                                            final meal = meals[index];
                                            final isLastItem = index == 3 - 1;

                                            return Column(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        spreadRadius: 2,
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () =>
                                                            _showMealDialog(
                                                                context, meal),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 60,
                                                                height: 60,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  gradient:
                                                                      LinearGradient(
                                                                    colors: [
                                                                      const Color
                                                                          .fromRGBO(
                                                                          3,
                                                                          218,
                                                                          198,
                                                                          0.7),
                                                                      MyColors
                                                                          .secondaryColor,
                                                                    ],
                                                                    begin: Alignment
                                                                        .topLeft,
                                                                    end: Alignment
                                                                        .bottomRight,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    meal.name[0]
                                                                        .toUpperCase(),
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          24,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 16),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      meal.name,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            4),
                                                                    Text(
                                                                      '${meal.calories} calories',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .grey[600],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            2),
                                                                    Text(
                                                                      DateFormat(
                                                                              'dd/MM/yyyy at HH:mm')
                                                                          .format(
                                                                              meal.consumptionDateTime),
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .grey[500],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .edit),
                                                                    color: Theme.of(
                                                                            context)
                                                                        .primaryColor,
                                                                    onPressed: () =>
                                                                        _showMealDialog(
                                                                            context,
                                                                            meal),
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .delete),
                                                                    color: Colors
                                                                        .redAccent,
                                                                    onPressed: () =>
                                                                        _confirmDelete(
                                                                            context,
                                                                            meal),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (isLastItem &&
                                                    meals.length > 3)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 16, bottom: 8),
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                const ListMealsPage(),
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Color.fromRGBO(3,
                                                                218, 198, 0.7),
                                                        minimumSize: const Size(
                                                            double.infinity,
                                                            50),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            'Voir plus',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Icon(
                                                              Icons
                                                                  .arrow_forward,
                                                              color:
                                                                  Colors.white),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (!isLastItem)
                                                  const SizedBox(height: 16),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                          },
                        ),
                        floatingActionButton: FloatingActionButton(
                          child: const Icon(Icons.add),
                          onPressed: () => _showMealDialog(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildMetricColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: MyColors.secondaryColor,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: const Color.fromRGBO(0, 0, 0, 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: MyColors.textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<Map<String, String>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    Map<String, String> userInfo = {};
    if (token != null) {
      final Map<String, dynamic> decodedToken = jsonDecode(token);
      userInfo = {
        'fullname': decodedToken['fullname'] ?? 'Unknown',
        'email': decodedToken['email'] ?? 'Unknown',
        'height': decodedToken['height']?.toString() ?? 'Unknown',
        'weight': decodedToken['weight']?.toString() ?? 'Unknown',
      };
    }

    return userInfo;
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
                    borderSide:
                        BorderSide(color: MyColors.secondaryColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        BorderSide(color: MyColors.secondaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.restaurant_menu,
                      color: MyColors.secondaryColor),
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
                        BorderSide(color: MyColors.secondaryColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        BorderSide(color: MyColors.secondaryColor, width: 2),
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
                          Icon(Icons.calendar_today,
                              color: MyColors.secondaryColor),
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
            backgroundColor: MyColors.secondaryColor,
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

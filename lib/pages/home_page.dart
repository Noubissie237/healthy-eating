import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/meal_provider.dart';
import 'package:food_app/pages/list_meals_page.dart';
import 'package:food_app/utils/utils.dart';
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
                    const Expanded(
                      flex: 4,
                      child: ListMealsPage(),
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
                    const Expanded(
                      flex: 4,
                      child: ListMealsPage(),
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
}

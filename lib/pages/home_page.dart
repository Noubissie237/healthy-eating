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
    return FutureBuilder<Map<String, String>>(
        future: _getUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text("Data loading error"));
          }

          final userInfo = snapshot.data!;

          return Scaffold(
            // backgroundColor: const Color.fromARGB(40, 76, 175, 79),
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(40, 76, 175, 79),
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
            body: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "Hi, ${userInfo['fullname'].toString().split(' ').last.substring(0, 1).toUpperCase()}${userInfo['fullname'].toString().split(' ').last.substring(1).toLowerCase()} 😊",
                          style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.06),
                        ),
                      ],
                    ),
                  ),
                ),
                Text("Repas enrégistrées"),
                const SizedBox(height: 15),
                Expanded(
                  flex: 5,
                  child: ListMealsPage(),
                ),
              ],
            ),
          );
        });
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

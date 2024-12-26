import 'package:flutter/material.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
        future: _getUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Data loading error"));
          }

          final userInfo = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: const Text("Personal Information"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          const CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                AssetImage('assets/images/user.webp'),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 18,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildInfoTile(
                        context, "fullname", userInfo["fullname"] ?? "Unknown"),
                    buildInfoTile(
                        context, "Email", userInfo["email"] ?? "Unknown"),
                    buildInfoTile(
                        context, "height (cm)", userInfo["height"] ?? "Unknown",
                        onTap: () {
                      _showHeightDialog(
                          context, userInfo["height"], userInfo["email"]);
                    }),
                    buildInfoTile(context, "weight (Kg)",
                        userInfo["weight"] ?? "Unknown"),
                  ],
                ),
              ),
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
        'prenom': decodedToken['prenom'] ?? 'Unknown',
        'telephone': decodedToken['telephone'] ?? 'Unknown',
        'email': decodedToken['email'] ?? 'Unknown',
        'height': decodedToken['height']?.toString() ?? 'Unknown',
        'weight': decodedToken['weight']?.toString() ?? 'Unknown',
      };
    }
    return userInfo;
  }

  Widget buildInfoTile(BuildContext context, String title, String value,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            subtitle: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 18,
            ),
          ),
          Divider(color: Colors.grey[300]),
        ],
      ),
    );
  }

  void _showHeightDialog(
      BuildContext context, String? currentHeight, String? email) {
    final TextEditingController heightController = TextEditingController();
    if (currentHeight != null && currentHeight != "Unknown") {
      heightController.text = currentHeight;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Height"),
          content: TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: "Enter new height (cm)"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newHeight = double.tryParse(heightController.text);
                if (newHeight != null && email != null) {
                  // Update the height in the database
                  final dbHelper = DatabaseHelper();
                  await dbHelper.updateHeight(email, newHeight);

                  // Update SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('user_token');

                  if (token != null) {
                    final Map<String, dynamic> decodedToken = jsonDecode(token);
                    decodedToken['height'] =
                        newHeight; // Mettre à jour la hauteur
                    // Convertir à nouveau en JSON et sauvegarder
                    await prefs.setString(
                        'user_token', jsonEncode(decodedToken));
                  }

                  Navigator.of(context).pop();
                } else {
                  // Affichez un message d'erreur si la valeur n'est pas valide
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter a valid height")),
                  );
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}

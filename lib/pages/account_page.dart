import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Future<Map<String, String>> _userInfoFuture;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = _getUserInfo();
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

  Future<void> _refreshUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token != null) {
      final Map<String, dynamic> decodedToken = jsonDecode(token);
      final String email = decodedToken['email'];

      final dbHelper = DatabaseHelper();
      final userData = await dbHelper.getUserByEmail(email);

      if (userData != null) {
        decodedToken['height'] = userData['height']?.toString();
        decodedToken['weight'] = userData['weight']?.toString();

        await prefs.setString('user_token', jsonEncode(decodedToken));
      }
    }

    // Recharger les données après le rafraîchissement
    setState(() {
      _userInfoFuture = _getUserInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _userInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Data loading error"));
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
          body: RefreshIndicator(
            onRefresh: _refreshUserInfo,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
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
                  buildInfoTile(context, "Fullname",
                      userInfo["fullname"] ?? "Unknown", false, onTap: () {
                    downMessage(
                        context,
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: MyColors.orange,
                        ),
                        'You can\'t update this field  !');
                  }),
                  buildInfoTile(
                      context, "Email", userInfo["email"] ?? "Unknown", false,
                      onTap: () {
                    downMessage(
                        context,
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: MyColors.orange,
                        ),
                        'You can\'t update this field  !');
                  }),
                  buildInfoTile(context, "Height (cm)",
                      userInfo["height"] ?? "Unknown", true, onTap: () {
                    _showHeightDialog(
                        context, userInfo["height"], userInfo["email"]);
                  }),
                  buildInfoTile(context, "Weight (Kg)",
                      userInfo["weight"] ?? "Unknown", true, onTap: () {
                    _showWeightDialog(
                        context, userInfo['weight'], userInfo["email"]);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildInfoTile(
      BuildContext context, String title, String value, bool updatable,
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
            trailing: updatable
                ? Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 18,
                  )
                : null,
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
                  final dbHelper = DatabaseHelper();
                  await dbHelper.updateHeight(email, newHeight);

                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('user_token');

                  if (token != null) {
                    final Map<String, dynamic> decodedToken = jsonDecode(token);
                    decodedToken['height'] = newHeight;
                    await prefs.setString(
                        'user_token', jsonEncode(decodedToken));
                  }

                  setState(() {
                    _userInfoFuture = _getUserInfo();
                  });

                  Navigator.of(context).pop();
                } else {
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

  void _showWeightDialog(
      BuildContext context, String? currentWeight, String? email) {
    final TextEditingController weightController = TextEditingController();
    if (currentWeight != null && currentWeight != "Unknown") {
      weightController.text = currentWeight;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Weight"),
          content: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: "Enter new weight (kg)"),
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
                final newWeight = double.tryParse(weightController.text);
                if (newWeight != null && email != null) {
                  final dbHelper = DatabaseHelper();
                  await dbHelper.updateWeight(email, newWeight);

                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('user_token');

                  if (token != null) {
                    final Map<String, dynamic> decodedToken = jsonDecode(token);
                    decodedToken['weight'] = newWeight;
                    await prefs.setString(
                        'user_token', jsonEncode(decodedToken));
                  }

                  setState(() {
                    _userInfoFuture = _getUserInfo();
                  });

                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter a valid weight")),
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

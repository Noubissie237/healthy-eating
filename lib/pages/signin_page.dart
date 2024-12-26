import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SigninPageState();
  }
}

class _SigninPageState extends State<SigninPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void unFocusMethod() {
    FocusScope.of(context).unfocus();
  }

  void login() async {
    final dbHelper = DatabaseHelper();

    // Récupérer l'utilisateur par son login et mot de passe
    final user = await dbHelper.getUserByLogin(
      _loginController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();

      // Convertir l'utilisateur en token JSON
      final userToken = jsonEncode({
        "nom": user.nom,
        "prenom": user.prenom,
        "telephone": user.telephone,
        "email": user.email,
        "taille": user.taille,
        "poids": user.poids,
      });

      await prefs.setString("user_token", userToken);

      // Rediriger vers la page principale après la connexion
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/main',
        (Route<dynamic> route) => false,
      );
    } else {
      String nature = int.tryParse(_loginController.text) != null
          ? "Numéro de téléphone"
          : "Email";
      String message = "$nature ou mot de passe incorrect.";

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_sharp, color: Colors.red),
          title: const Text("Échec de connexion"),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ok"),
            ),
          ],
        ),
      );
    }

    _loginController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: GestureDetector(
        onTap: unFocusMethod,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/logo.png",
                    width: MediaQuery.of(context).size.width * 0.5),
                Text(
                  "Connexion",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      createField(
                          context,
                          'Téléphone / Email',
                          '',
                          false,
                          _loginController,
                          TextInputType.emailAddress,
                          0,
                          null),
                      createField(
                          context,
                          'Mot de passe',
                          'Entrez votre mot de passe',
                          true,
                          _passwordController,
                          TextInputType.number,
                          4,
                          4),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      ElevatedButton(
                          onPressed: () {
                            unFocusMethod();
                            if (_formKey.currentState!.validate()) {
                              login();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyColors.primaryColor,
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.1,
                                vertical: 10),
                          ),
                          child: const Text(
                            "Se connecter",
                            style: TextStyle(color: MyColors.textColor),
                          )),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Vous n'avez pas de compte ? "),
                          TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: const Text('Inscrivez-vous'))
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

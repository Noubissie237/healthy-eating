//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import '../models/users.dart';
import '../database/database_helper.dart';
import '../utils/utils.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SignupPageState();
  }
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _submitForm() async {
    _formKey.currentState!.save();
    Users user = Users(
        nom: _nomController.text,
        prenom: _prenomController.text,
        telephone: _telephoneController.text,
        email: _emailController.text,
        password: _passwordController.text);

    await _databaseHelper.insertStudent(user);

    _imageController.clear();
    _nomController.clear();
    _prenomController.clear();
    _emailController.clear();
    _telephoneController.clear();
    _passwordController.clear();
  }

  @override
  void initState() {
    super.initState();
    _imageController.text = 'assets/images/default-user.png';
  }

  @override
  void dispose() {
    _imageController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void unFocusMethod() {
    FocusScope.of(context).unfocus();
  }

  // void _handlePickImage() async {
  //   File? image = await pickImage();
  //   if (image != null) {
  //     setState(() {
  //       _imageController.text = image.path;
  //     });
  //   }
  // }

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
                  "Inscription",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      createField(context, 'Nom', 'Entrez votre nom', false,
                          _nomController, TextInputType.name, 3, null),
                      createField(
                          context,
                          'Prenom',
                          'Entrez votre prenom',
                          false,
                          _prenomController,
                          TextInputType.name,
                          3,
                          null),
                      createField(context, 'Email', 'xyz@gmail.com', false,
                          _emailController, TextInputType.emailAddress, 3, null),
                      createField(context, 'Téléphone', '690232120', false,
                          _telephoneController, TextInputType.number, 9, 9),
                      createField(context, 'Mot de passe', '', true,
                          _passwordController, TextInputType.number, 4, 4),
               
                      ElevatedButton(
                          onPressed: () {
                            unFocusMethod();
                            if (_formKey.currentState!.validate()) {
                              _submitForm();
                              downMessage(
                                  context,
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: MyColors.success,
                                  ),
                                  'successful registration  !');
                              Navigator.pushNamedAndRemoveUntil(context,
                                  '/main', (Route<dynamic> route) => false);
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
                            "S'inscrire",
                            style: TextStyle(color: MyColors.textColor),
                          )),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Vous avez déjà un compte ? "),
                          TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signin');
                              },
                              child: const Text('Connectez-vous'))
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

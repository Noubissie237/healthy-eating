import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();

      bool emailExists = await _databaseHelper.doesEmailExist(email);
      if (emailExists) {
        downMessage(
          context,
          const Icon(
            Icons.error,
            color: Colors.red,
          ),
          'This email already exist !',
        );
        return;
      } else {
        Users user = Users(
          fullname: _fullnameController.text.toString().trim().toUpperCase(),
          email: email,
          password: _passwordController.text,
        );

        await _databaseHelper.insertStudent(user);
        final userTmp = await _databaseHelper.getUserByEmail(email);

        final prefs = await SharedPreferences.getInstance();
        final userToken = jsonEncode({
          "id": userTmp?['id'],
          "fullname": _fullnameController.text.toString().trim().toUpperCase(),
          "email": email,
          "height": null,
          "weight": null,
        });

        await prefs.setString("user_token", userToken);

        _fullnameController.clear();
        _emailController.clear();
        _passwordController.clear();

        downMessage(
            context,
            const Icon(
              Icons.check_circle_outline,
              color: MyColors.success,
            ),
            'successful registration  !');

        Navigator.pushNamedAndRemoveUntil(
            context, '/main', (Route<dynamic> route) => false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void unFocusMethod() {
    FocusScope.of(context).unfocus();
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
                  "Registration",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      createField(
                          context,
                          'Fullname',
                          'Enter your fullname',
                          false,
                          _fullnameController,
                          TextInputType.name,
                          3,
                          null),
                      createField(
                          context,
                          'Email',
                          'xyz@gmail.com',
                          false,
                          _emailController,
                          TextInputType.emailAddress,
                          3,
                          null),
                      createField(context, 'Password', '', true,
                          _passwordController, TextInputType.number, 4, 4),
                      ElevatedButton(
                          onPressed: () {
                            unFocusMethod();
                            if (_formKey.currentState!.validate()) {
                              _submitForm();
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
                            "REGISTER",
                            style: TextStyle(color: MyColors.textColor),
                          )),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account ? "),
                          TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signin');
                              },
                              child: const Text('Login'))
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

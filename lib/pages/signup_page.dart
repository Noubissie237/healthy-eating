import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:food_app/colors/my_colors.dart';
import 'package:food_app/database/database_helper.dart';
import 'package:food_app/models/users.dart';
import 'package:food_app/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _databaseHelper = DatabaseHelper();
  bool _isLoading = false;

  late final TextEditingController _fullnameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullnameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      if (await _databaseHelper.doesEmailExist(email)) {
        _showErrorMessage('This email already exists!');
        return;
      }

      await _registerUser(email);
      _navigateToMain();
    } catch (e) {
      _showErrorMessage('Registration failed. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerUser(String email) async {
    final user = Users(
      fullname: _fullnameController.text.trim().toUpperCase(),
      email: email,
      password: _passwordController.text,
    );

    await _databaseHelper.insertStudent(user);
    final userTmp = await _databaseHelper.getUserByEmail(email);
    await _saveUserToken(userTmp, email);

    _showSuccessMessage();
    _clearForm();
  }

  Future<void> _saveUserToken(
      Map<String, dynamic>? userTmp, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = jsonEncode({
      'id': userTmp?['id'],
      'fullname': _fullnameController.text.trim().toUpperCase(),
      'email': email,
      'height': null,
      'weight': null,
    });

    await prefs.setString('user_token', userToken);
  }

  void _showErrorMessage(String message) {
    downMessage(
      context,
      const Icon(Icons.error, color: Colors.red),
      message,
    );
  }

  void _showSuccessMessage() {
    downMessage(
      context,
      const Icon(Icons.check_circle_outline, color: MyColors.success),
      'Registration successful!',
    );
  }

  void _clearForm() {
    _fullnameController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  void _navigateToMain() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/main',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(context),
                _buildTitle(context),
                const SizedBox(height: 32.0),
                _buildForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Image.asset(
      "assets/images/logo.png",
      width: MediaQuery.of(context).size.width * 0.5,
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      "Registration",
      style: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.06,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            label: 'Fullname',
            hint: 'Enter your fullname',
            controller: _fullnameController,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 16.0),
          _buildTextField(
            label: 'Email',
            hint: 'xyz@gmail.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16.0),
          _buildTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            isPassword: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          const SizedBox(height: 24.0),
          _buildSubmitButton(),
          const SizedBox(height: 16.0),
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: MyColors.secondaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 48.0,
          vertical: 12.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text(
              "REGISTER",
              style: TextStyle(
                color: MyColors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/signin'),
          child: const Text('Login'),
        ),
      ],
    );
  }
}
